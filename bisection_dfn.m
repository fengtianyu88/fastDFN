%% Bisection Algorithm for Optimal \beta in DFN Reference Governor
%   Created July 25, 2012 by Scott Moura

function [beta_star] = bisection_dfn(p,x0,z0,I0,Ir)

%% Bisection Algorithm Parameters
maxiters = 25;
beta = zeros(maxiters,1);
beta(1) = 1;

beta_low = 0;
beta_high = 1;
beta_err = 0.005;


%% Bisection Algorithm
for idx = 1:maxiters
    
    % Simulate DFN Model forward
    try
        yc = dfn_rg_forward(p,x0,z0,I0,Ir,beta(idx));
    catch err
        yc = [1 1];
    end
    
    % Constraints Satisfied?
    if(yc <= 0)
    
        % Test Tolerances
        if(idx == 1)
            beta_star = 1;
            break;
        elseif( abs(beta(idx) - beta(idx-1)) <= beta_err)
            beta_star = beta(idx);
            break;
        else
            beta_low = beta(idx);
        end

    % Constraints NOT satisfied
    else
        
        beta_high = beta(idx);
        
    end
    
    % Bisection
    beta(idx+1) = (beta_high + beta_low)/2;
    
end

fprintf(1,'Bisection Iters = %2.0f | beta = %1.4f\n',idx,beta(idx));
beta_star = beta(idx);

%% Simulate DFN Model Forward
function yc = dfn_rg_forward(p,x0,z0,I0,Ir,beta)

% Simulation Horizon
NT = 5;

% Preallocate & Initialize
I = zeros(NT,1);
I(1) = I0;

x = zeros(length(x0), NT);
z = zeros(length(z0), NT);

x(:,1) = x0;
z(:,1) = z0;

% Preallocate and initailize Constrained outputs
c_ss_p_Lp =  zeros(NT,1); % Niloofar add
c_ss_p_Lp(1) = p.c_s_p_max * p.theta_min_p; % Niloofar add

c_ss_n_Ln =  zeros(NT,1); % Niloofar add
c_ss_n_Ln(1) = p.c_s_n_max * p.theta_min_n; % Niloofar add

c_e_0n = zeros(NT,1);
c_e_0n(1) = p.rg.c_e_min;

c_e_0p = zeros(NT,1);
c_e_0p(1) = p.rg.c_e_min;

Temp = zeros(NT,1); % Niloofar added
Temp(1) = p.rg.T_min;  % Niloofar added  

% eta_s_Ln = zeros(NT,1);
% 
% Volt = zeros(NT,1);
% Volt(1) = 3.7; % Niloofar added

% Simulate Forward
for k = 1:(NT-1)
    
    % Reference Governor
%     I(k+1) = I(k) + beta * (Ir - I(k));
    I(k+1) = beta*Ir;
    
    % Current
    if(k == 1)
        Cur_vec = [I(k), I(k), I(k+1)];
    else
        Cur_vec = [I(k-1), I(k), I(k+1)];
    end
    
    % Step-forward in time
    [x(:,k+1), z(:,k+1)] = cn_dfn(x(:,k),z(:,k),Cur_vec,p);

    % Output data
    [~, ~, y] = dae_dfn(x(:,k+1),z(:,k+1),I(k+1),p);
    
    
    % Constraint Outputs
    c_ss_n(:,k+1) = y(1:Nn);
    c_ss_p(:,k+1) = y(Nn+1:Nnp);
    
    c_ex(:,k+1) = y(2*Nnp+1:2*Nnp+Nx+4);
    
%     eta_n(:,k+1) = y(2*Nnp+Nx+4+1 : 2*Nnp+Nx+4+Nn);
%     eta_p(:,k+1) = y(2*Nnp+Nx+4+Nn+1 : 2*Nnp+Nx+4+Nn+Np);
    
    c_e_0n(k+1) = y(end-5);
    c_e_0p(k+1) = y(end-4);
    
%     eta_s_Ln(k+1) = y(end-3);
    
%     Volt(k+1) = y(end-2);

end

if(k == NT-1)
    yc = [c_e_min-c_e_0n, c_e_min-c_e_0p, -eta_s_Ln , ...      
         c_e_0n-c_e_max, c_e_0p-c_e_max , ...   % Niloofar added
         T_min-Temp , Temp-T_max,...                    
        (c_ss_p_0p/c_s_p_max)-theta_max_p, ...
        (c_ss_p_Lp/c_s_p_max)-theta_max_p, ...
        theta_min_p-(c_ss_p_0p/c_s_p_max), ...
        theta_min_p-(c_ss_p_Lp/c_s_p_max), ...
        (c_ss_n_0n/c_s_n_max)-theta_max_n, ...
        (c_ss_n_Ln/c_s_n_max)-theta_max_n, ...
        theta_min_n-(c_ss_n_0n/c_s_n_max), ...
        theta_min_n-(c_ss_n_Ln/c_s_n_max)];%, ... % negative if you violate

% yc = [Volt_min-Volt, Volt-Volt_max]; % Niloofar added (use voltage as the only constraint)
end


