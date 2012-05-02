%%%%%%%%%%%% simulation
close all
clear all
clc
% Initial states

N =200;



%-------------------------- parameters
% - P: the perceptual model parameters vector, ie. P = [ka;om;th], using
% s2 = ka*x3+om
% s3 = th


ka = 1;
om = 10;
th = 1;

in.lev3 = 1;
in.thub = 2; % upper bound on theta (lower being 0)
in.kaub = 2; % upper bound on kappa (lower being 0)

% This parameter does not figure in the initial paper.
% When updated, variance on 3rd level state can get negative
% this happens during a reduction of the variance.
% When this happens, an alternative update is performed through a
% rescaling.
in.rf = 0;

theta = [sigm(ka/in.kaub,struct('INV',1));om;sigm(th/in.thub,struct('INV',1))];

%-------------------------- initial states

x0 = zeros(7,1);
x0(1)=0;%   mu1 = x(1);
x0(2)=0;%   mu2 = x(2);
x0(3)=10;%   sa2 = x(3);
x0(4)=10;%   mu3 = x(4);
x0(5)=10;%   sa3 = x(5);


%-------------------------- inversion
alpha = Inf;
sigma = Inf;
options.binomial = 1;
options.inG = in;
options.inF = in;

%------------------------- Simulating data



% simulate Qlearning
beta = 3;
alpha = 0.1;
R = [rand(1,N/2)<0.2,rand(1,N/2)<0.8;rand(1,N/2)<0.8,rand(1,N/2)<0.2];
 [A,r,Q,p]=simulate_QLearning_2Q([0;0],alpha,beta,R);
figure
 plot(Q')
 hold on
 plot(A','x')

y = A; % data generated by the model we want to invert is the index of the chosen action
u = [A+1;r]; % data needed for model inversion is 
dim_output = 1; % 
dim_data = 2; % index of sequence/reward 
dim = struct('n',2*7,...  %2 (models)* 7 (hidden states) * Nsessions
             'p',dim_output,... % total output dimension
             'n_theta',3,... % evolution parameters
             'n_phi', 1,... % observation parameters
             'n_t',N);

         
%----------------------------------
% In order to simulate decisons for the task I'm considering
% Feedbacks of all possible outputs must be given as an input.
% (this is more than what is requested for inversion, where only the feedback actually recieved is of interest)
         
% Here: two alternatives
R = [rand(1,N/2)<0.2,rand(1,N/2)<0.8;rand(1,N/2)<0.8,rand(1,N/2)<0.2]; % rewards for both alternatives
% Organization of data
% u : 
%   1. index of the chosen sequence
%   2...Na+1. rewards for all alternatives
u = [zeros(1,N); % not needed for simulation purpose
     R]; % 

 
%----- Simulating data
f_fname = @f_Mathys_binary_feedback;
g_fname = @g_Mathys_binary_feedback; 
[y,x,x0,eta,e] = simulateNLSS(N,f_fname,g_fname,theta,phi,u,alpha,sigma,options,x0)

 
 
 
         

%%




% Defining Priors
% Priors on parameters (mean and Covariance matrix)
priors.muPhi = zeros(dim.n_phi,1); 
priors.muTheta = zeros(dim.n_theta,1);
priors.SigmaPhi = 1e1*eye(dim.n_phi);
priors.SigmaTheta = 1e1*eye(dim.n_theta);
% Priors on initial 
priors.muX0 = 0*ones(dim.n,1);
priors.muX0([4,11]) = -4;%-4;  % setting volatility
priors.SigmaX0 = 1e1*eye(dim.n);
% No state noise for deterministic update rules
priors.a_alpha = Inf;
priors.b_alpha = 0;
% Defining parameters for sessions

options.inF = in;
options.inG = in;
options.priors = priors;
options.DisplayWin = 1;
options.GnFigs = 0;
options.binomial = 1; % Dealing with binary data
options.isYout = zeros(1,N); % Excluding data points

f_fname = @f_Mathys_binary_feedback;
g_fname = @g_Mathys_binary2;

%%
% options.maxIter = 0;
% options.MaxIterInit = 0;
% options.GnMaxIter = 0;
[posterior,out] = VBA_NLStateSpaceModel(y,u,f_fname,g_fname,dim,options);

 
 
%x0(1)=0;%   mu1 = x(1);
%x0(2)=0;%   mu2 = x(2);
%x0(3)=10;%   sa2 = x(3);
%x0(4)=10;%   mu3 = x(4);
%x0(5)=10;%   sa3 = x(5);
% posterior.muX(1,:)
% posterior.muX(3,:)
 
% posterior.muPhi
% posterior.muTheta
 
 
% Analysis of components
%   mu1 = x(1);
%   mu2 = x(2);
%   sa2 = x(3);
%   mu3 = x(4);
%   sa3 = x(5);
%%
figure
hold on
plot(posterior.muX(2,:),'r')
plot( sigm(posterior.muX(2,:)),'.-r')
plot(posterior.muX(9,:),'b')
plot( sigm(posterior.muX(9,:)),'.-b')
title('Outcome probabilities for each alternative')
%%
figure
hold on
plot(posterior.muX(4,:),'r')
plot(posterior.muX(11,:),'b')
title('volatility for each alternative')

% displayResults(posterior,out,y,x,x0,theta,phi,alpha,sigma)