%% CR3BP Library %% 
% Sergio Cuevas del Valle
% Date: 17/03/20
% File: linrel_motion.m 
% Issue: 0 
% Validated: 

%% Linear relative motion model in the CR3BP %%
% This function contains several linear relative motion models between two punctual particles in the 
% circular restricted three body problem. It accounts for the two masses moving in the normalized, 
% non dimensional synodic frame define by the two primaries, which are assumed to be in the same 
% plane and in circular orbits. 

% Inputs: - scalar mu, the reduced gravitational parameter of the system. 
%         - scalar direction (in binary format, 1 or -1), indicating the
%           time integration direction: 1 for forward integration, -1 for
%           backward integration.
%         - boolean flagVar, true for dyanmics and STM integration, 
%           false for only dynamical integration.
%         - scalar t, a reference epoch. 
%         - vector s, containing in an Nx1 array the phase space vector,
%           possibly augmented with the state transition matrix at time t. 

% Outputs: - vector dr, the differential vector field, which will include
%            the phase space trajectory.

% Methods: . 

% New versions: include the first variations of the vector field.

function [ds] = linrel_model(mu, direction, flagVar, model, t, s, varargin)
    %State variables 
    s_t = s(1:6);       %State of the target
    rho = s(7:12);      %State of the chaser
    
    %Equations of motion of the target
    ds_t = cr3bp_equations(mu, direction, flagVar, t, s_t);        %Target equations of motion
    
    %Equations of motion of the relative state 
    switch (model)
        case 'Target'
            drho = target_centered(mu, s_t, rho);                  %Relative motion equations
        case 'Libration'
            drho = libration_centered(rho, varargin);              %Relative motion equations
        otherwise
            drho = [];
            disp('No valid model was chosen');
    end
    
    %Vector field 
    ds = [ds_t; drho];
end

%% Auxiliary functions 
%Relative motion equations linearized with respect to the target
function [drho] = target_centered(mu, s_t, s_r)
    %Constants of the system 
    mu1 = 1-mu;             %Reduced gravitational parameter of the first primary 
    mu2 = mu;               %Reduced gravitational parameter of the second primary 
    
    %State variables 
    r_t = s_t(1:3);         %Synodic position of the target
    
    %Synodic position of the primaries 
    R1 = [-mu; 0; 0];       %Synodic position of the first primary
    R2 = [1-mu; 0; 0];      %Synodic position of the second primary
    
    %Relative position between the primaries and the target 
    Ur1 = r_t-R1;                           %Position of the target with respect to the first primary
    ur1 = Ur1/norm(Ur1);                    %Unit vector of the relative position of the target with respect to the primary
    Ur2 = r_t-R2;                           %Position of the target with respect to the first primary
    ur2 = Ur2/norm(Ur2);                    %Unit vector of the relative position of the target with respect to the primary
    
    %Relative acceleration (non inertial)
    O = zeros(3,3);                         %3 by 3 null matrix
    I = eye(3);                             %3 by 3 identity matrix
    Omega = [0 1 0; -1 0 0; 0 0 0];         %Hat map dyadic of the angular velocity for the synodice reference frame
    
    %Gravity acceleration
    Sigma = -((mu1/norm(Ur1)^3)+(mu2/norm(Ur2))^3)*eye(3)+3*((mu1/norm(Ur1)^3)*(ur1*ur1.')+(mu2/norm(Ur2)^3)*(ur2*ur2.'));
    
    %State matrix 
    A = [O I; Sigma-Omega*Omega -2*Omega];
    
    %Equations of motion 
    drho = A*s_r;
end

%Relative motion equations linearized with respect to a libration point
function [drho] = libration_centered(s_r, varargin)    
    %Linear Legendre coefficient c2           
    c2 = varargin{1};                       %Second Legendre coefficient
    c2 = c2{1};                             %Second Legendre coefficient
    
    %Relative acceleration (non inertial)
    O = zeros(3,3);                         %3 by 3 null matrix
    I = eye(3);                             %3 by 3 identity matrix
    Omega = [0 1 0; -1 0 0; 0 0 0];         %Hat map dyadic of the angular velocity for the synodice reference frame
    
    %Gravity acceleration
    Sigma = [1-2*c2 0 0; 0 1+c2 0; 0 0 c2];
    
    %Equations of motion 
    drho = [O I; Sigma -2*Omega]*s_r;
end

