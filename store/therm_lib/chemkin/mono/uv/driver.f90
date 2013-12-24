program driver
   use chem
   use chem_var
   implicit none
   character*100    buf
   double precision rho,E,T, MWave,kappa,mu, tout
   double precision tign,Teq
   double precision Y(2)
   double precision vrho(max_ns)

   !read files
   call init_therm

   !calc stoichiometry
   Y(1)=1d0/(1d0+of)
   Y(2)=1d0-Y(1)
   rho =1d0/(Y(1)/rhof+Y(2)/rhoo)
   vrho=rho*(vwf*Y(1)+vwo*Y(2))
   T   =      Tf*Y(1)+ To*Y(2)
   !call plot_time_history(T,vrho,5d-3,1000)
   !call plot_time_history(T,vrho,5d-3,1000)
   call calc_Tign_Teq(T,vrho,tign,Teq)
   print *,tign,Teq
   !print '(a,  f15.7)',"Y of f    ",Y(1)
   !print '(a,  f15.7)',"MWave     ",MWave
   !print '(a,  f15.7)',"kappa     ",kappa
   !print '(a,  f15.7)',"T         ",T
   !print '(a, es15.7)',"mu(mPoise)",mu*1d3*1d1
   !!print '(a,(10es9.1))',"Yv        ",Yv
   !!print '(a,(10es9.1))',"vhi       ",vhi
   !print '(a, es15.7)',"Enthalpy",  sum(Yv*vhi,1)
   !print '(a, es15.7)',"Enthalpy",  E+Ru*1d3/MWave*T

   !print '(a)',"*** at equilibrium *****************************"
   !print '(a, es15.7)',"        o/f ratio   =",of
   !print '(a,  f15.7)',"        P(bar)      =",rho*Ru*1d3/MWave*T*1d-5
   !print '(a,  f15.7)',"        rho(kg/m^3) =",rho
   !print '(a,  f15.7)',"        T(K)        =",T
   !print '(a, es15.7)',"        E(J/kg)     =",E
   !print '(a,  f15.7)',"        average MW  =",MWave
   !print '(a,  f15.7)',"        kappa       =",kappa
   !print '(a, es15.7)',"        mu(mPoise)  =",mu*1d3*1d1
end program driver
