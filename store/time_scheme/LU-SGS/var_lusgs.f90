module var_lusgs
   use grbl_prmtr
   double precision    Ap(1:dimq, 1:dimq, 0:nimax+1, 0:njmax+1,Nplane)
   double precision    Am(1:dimq, 1:dimq, 0:nimax+1, 0:njmax+1,Nplane)
   double precision    Bp(1:dimq, 1:dimq, 0:nimax+1, 0:njmax+1,Nplane)
   double precision    Bm(1:dimq, 1:dimq, 0:nimax+1, 0:njmax+1,Nplane)

   double precision alpha(1:nimax, 1:njmax,Nplane)

   double precision dsci(1:nimax,1:njmax,Nplane)
   double precision dscj(1:nimax,1:njmax,Nplane)

   double precision vnci(1:2,1:nimax,1:njmax,Nplane)
   double precision vncj(1:2,1:nimax,1:njmax,Nplane)
end module var_lusgs

