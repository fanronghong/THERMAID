function test_suite=test_examples
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;
end

function test_ex1
evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');
load  examples/comsol_bench_h.mat

global k_ratio
k_ratio = 1e3; % Run with Kf/Km = 1e3

THERMAID('Input_ex1',0)

udata = evalin('base','udata');
x     = evalin('base','x');
p     = evalin('base','p');
pf    = evalin('base','pf');

xf = 0:udata.dxf:5;
xf = xf(1:udata.Nf_i(1));

pm_1e3_EDFM   = p(:,floor(udata.Nf(2)/2));
pf_1e3_EDFM   = pf(udata.Nf_i(1)+1:udata.Nf_f);

pf_interp_1e3 = interp1(x_pf_1e3,pf_1e3,xf');
pm_interp_1e3 = interp1(x_pm_1e3,pm_1e3,x');
pm_interp_1e3(isnan(pm_interp_1e3)) = 0;

RMSE_pf_1e3 = sqrt(mean((pf_1e3_EDFM-pf_interp_1e3).^2))/(max(pf_interp_1e3)-min(pf_interp_1e3));
RMSE_pm_1e3 = sqrt(mean((pm_1e3_EDFM-pm_interp_1e3).^2))/(max(pm_interp_1e3)-min(pm_interp_1e3));

assertEqual(round(RMSE_pf_1e3 *1e7)/1e7,0.0050262);
assertEqual(round(RMSE_pm_1e3 *1e7)/1e7,0.0046731);

end

function test_ex2
evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');
load examples/comsol_bench_th2.mat

global k_ratio

% Run with Kf/Km = 1e5
k_ratio = 1e5;
THERMAID('Input_ex2',0)

udata = evalin('base','udata');
XY1     = evalin('base','XY1');
tNewf    = evalin('base','tNewf');

%% Post analysis
xf = udata.dxf/2:udata.dxf:abs(XY1(1,2)-XY1(end,3));

T_horz = tNewf(udata.Nf_i(1)+1:udata.Nf_f);
T_vert = tNewf(1:udata.Nf_i(1));

%% Quantitative analysis
x_interp = xf';
T_interp_horz = interp1(x_ref_T_horz,T_ref_horz,x_interp);

% Remove NaN from interpolation
T_interp_horz(end) = T_interp_horz(end-2);
T_interp_horz(end-1) = T_interp_horz(end-2);

T_interp_vert = interp1(x_ref_T_vert,T_ref_vert,x_interp);
T_interp_horz(end) = T_interp_horz(end-1);
T_interp_vert(end) = T_interp_vert(end-1);

RMSE_T_vert = sqrt(mean((T_vert-T_interp_vert).^2))/(max(T_interp_vert)-min(T_interp_vert));
RMSE_T_horz = sqrt(mean((T_horz-T_interp_horz).^2))/(max(T_interp_horz)-min(T_interp_horz));

assertEqual(round(RMSE_T_vert *1e6)/1e6,0.052653);
assertEqual(round(RMSE_T_horz *1e6)/1e6,0.011209);
end

function test_ex3
if moxunit_util_platform_is_octave()
    moxunit_throw_test_skipped_exception('Skip test due to unresolved octave differences.');
end
evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');

global k_ratio

% Run with Kf/Km = 1e5
k_ratio = 1e5;

THERMAID('Input_ex3',0);

pf    = evalin('base','pf');
p    = evalin('base','p');
tNewf    = evalin('base','tNewf');
tNew    = evalin('base','tNew');

load tests/reference_ex3.mat

p = round(p *1e2)./1e2;
p_ref = round(p_ref *1e2)./1e2;

assertElementsAlmostEqual(p,p_ref)
assertElementsAlmostEqual(pf,pf_ref)
assertElementsAlmostEqual(tNew,T_ref)
assertElementsAlmostEqual(tNewf,Tf_ref)
end

function test_ex4
if moxunit_util_platform_is_octave()
    moxunit_throw_test_skipped_exception('Skip test due to octave speed.');
end
evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');

THERMAID('Input_ex4',0);

pf    = evalin('base','pf');
p    = evalin('base','p');

load reference_ex4.mat

assertElementsAlmostEqual(p,p_ref)
assertElementsAlmostEqual(pf,pf_ref)
end

function test_ex5
if moxunit_util_platform_is_octave()
    moxunit_throw_test_skipped_exception('Skip test due to octave speed.');
end
evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');

THERMAID('Input_ex5',0);

pf    = evalin('base','pf');
p    = evalin('base','p');
tNewf    = evalin('base','tNewf');
tNew    = evalin('base','tNew');

load reference_ex5.mat

assertElementsAlmostEqual(p,p_ref)
assertElementsAlmostEqual(pf,pf_ref)
assertElementsAlmostEqual(tNew,T_ref)
assertElementsAlmostEqual(tNewf,Tf_ref)
end

function test_ex6

evalin('base','clear  calcVelocity initialize pressureSystem calc_interface_values_fracture');

THERMAID('Input_ex6',0);

p    = evalin('base','p');

pdiag = zeros(size(p,1),1);

for i = 1:size(p,1)
    pdiag(i) = p(i,i);
end

%% Analytical
k_ratio = 1e2;
a = 45*pi/180; % Fracture angle °
b_max = 0.05;  % Maximum fracture aperture [m]
L = 2; 
K_m = 1e-12;
K_f = K_m*k_ratio;
mu = 1e-3;
q0 = 1e-4;

x = linspace(-5,5,301);
y = linspace(-5,5,301);
[X,Y] = meshgrid(x,y);
z = X+1i*Y;
z1 = (-1+0i)*exp(1i*a);
z2 = (+1+0i)*exp(1i*a);

Z = (z-0.5*(z1+z2))/(0.5*(z2-z1));
A = 0.5*K_f*b_max/(K_m*L+K_f*b_max)*q0*L*cos(a);

l = 1;
o1 = -A.*sign(real(Z)).*sqrt((Z-l).*(Z+l));
o2 = A.*Z;
o3 = -0.5*q0*L.*exp(1i*a).*Z;

omega = o1 + o2 + o3;
phi = real(omega)*mu/K_m;

phidiag = zeros(size(phi,1),1);

for i = 1:size(phi,1)
    phidiag(i) = phi(i,i);
end


perror = sqrt(mean((pdiag-phidiag).^2))/(max(phidiag)-min(phidiag));
assertTrue(perror(1)<=0.0058);

end


