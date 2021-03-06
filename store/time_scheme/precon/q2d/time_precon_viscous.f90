subroutine calc_next_step_implicit(step_internal)
   use grbl_prmtr
   use mod_mpi
   use variable
   use var_lusgs
   implicit none
   integer,intent(in)::step_internal
   integer i,j,k,sm,plane
   double precision Dq(1:dimq,0:nimax+1,0:njmax+1,Nplane)
   double precision Dq_small(1:dimq)
   double precision omega,tmp
   double precision dp

   omega=1d300
   res = 0d0
   do plane = nps,npe
      !set RHS
      !$omp parallel do private(i,Dq_small)
      do j=nys(plane),nye(plane)
         do i=nxs(plane),nxe(plane)
            Dq_small= dsi(i-1,  j,plane)*(TGi(1:dimq,i-1,j  ,plane)-TGvi(1:dimq,i-1,j  ,plane))&
                     -dsi(  i,  j,plane)*(TGi(1:dimq,i  ,j  ,plane)-TGvi(1:dimq,i  ,j  ,plane))&
                     +dsj(  i,j-1,plane)*(TGj(1:dimq,i  ,j-1,plane)-TGvj(1:dimq,i  ,j-1,plane))&
                     -dsj(  i,  j,plane)*(TGj(1:dimq,i  ,j  ,plane)-TGvj(1:dimq,i  ,j  ,plane))&
                     +Area( i,  j,plane)*(Sq( 1:dimq,i  ,j  ,plane)+Svq( 1:dimq,i  ,j  ,plane))
            Dq(:,i,j,plane)= Dq_small+pre1(:,i,j,plane)*dot_product(dpdq(:,i,j,plane),Dq_small)
            Dq(:,i,j,plane)= Dq(:,i,j,plane)-Vol(i,j,plane)*dqdt(:,i,j,plane)
         end do
      end do
      !$omp end parallel do

      !set BC Delta q
      Dq(:,nxs(plane)-1,nys(plane)-1:nye(plane),plane)=0d0
      Dq(:,nxs(plane)-1:nxe(plane),nys(plane)-1,plane)=0d0

      !calculate forward
      do sm=nxs(plane)+nys(plane),nxe(plane)+nye(plane)
         !$omp parallel do private(j,Dq_small,dp)
         do i=max(nxs(plane),sm-nye(plane)),min(sm-nys(plane),nxe(plane))
            j=sm-i
            Dq_small = dsci(i-1,j  ,plane)*matmul(Ap(:,:,i-1,j  ,plane),Dq(:,i-1,j  ,plane))&
                      +dscj(i  ,j-1,plane)*matmul(Bp(:,:,i  ,j-1,plane),Dq(:,i  ,j-1,plane))
            Dq(:,i,j,plane)=alpha(i,j,plane)*(Dq(:,i,j,plane)+Dq_small)

            dq = phiq(i,j,plane)*dot_product(dpdq(:,i,j,plane),Dq(:,i,j,plane))
            Dq_small = phi(i,j,plane)*dpdq(nY+2,i,j,plane)*dp*pre1(:,i,j,plane)
            Dq_small(nY+2) = Dq_small(nY+2) + dp
            Dq(:,i,j,plane)=Dq(:,i,j,plane)+Dq_small
         end do
         !$omp end parallel do
      end do

      !set BC Delta q
      Dq(:,nxe(plane)+1,nys(plane):nye(plane)+1,plane)=0d0
      Dq(:,nxs(plane):nxe(plane)+1,nye(plane)+1,plane)=0d0

      !calculate backward
      do sm=nxe(plane)+nye(plane),nxs(plane)+nys(plane),-1
         !$omp parallel do private(j,k) reduction(min:omega) reduction(+:res)
         do i=max(nxs(plane),sm-nye(plane)),min(sm-nys(plane),nxe(plane))
            j=sm-i
            Dq(:,i,j,plane)=Dq(:,i,j,plane)&
                           -alpha(i,j,plane)*(dsci(i+1,j  ,plane)*matmul(Am(:,:,i+1,j  ,plane),Dq(:,i+1,j  ,plane))&
                                             +dscj(i  ,j+1,plane)*matmul(Bm(:,:,i  ,j+1,plane),Dq(:,i  ,j+1,plane)))

            res =res +Dq(nY+3,i,j,plane)**2
            !do k=1,dimq
            !   res =res +Dq(k,i,j,plane)**2
            !end do

            do k=1,nY
               if(Dq(k,i,j,plane)<0d0) then
                  omega = min(omega,-q(k,i,j,plane)/Dq(k,i,j,plane)*Dqmax)
                  if(omega<omega_min) then
                     print *,"Error: Omega becomes too small. omega = ",omega
                     call exit(1)
                  end if
               end if
            end do
         end do
         !$omp end parallel do
      end do
   end do

   !!!!!!!!! FOR PARAMETERS ADJUSTMENTS !!!!!!!!!!!!!!!!
   tmp = omega
   call MPI_Reduce(tmp,omega,1, MPI_DOUBLE_PRECISION, MPI_MIN, 0, MPI_COMM_WORLD, ierr)
   tmp = res
   call MPI_Reduce(tmp,  res,1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
   if(myid .eq. 0) then
      if(step_internal .eq. 1) res1 = res
      if(ILwrite) write(66,'(i3,100e9.1)') step_internal,omega,res/res1
   end if
   !!!!!!!!! END OF FOR PARAMETERS ADJUSTMENTS !!!!!!!!!

   omega      = min(omega_max,omega)

   do plane = nps,npe
      !add Dq
      !$omp parallel do private(i)
      do j=nys(plane),nye(plane)
         do i=nxs(plane),nxe(plane)
            q(:,i,j,plane)=q(:,i,j,plane)+omega*Dq(:,i,j,plane)
         end do
      end do
      !$omp end parallel do
   end do
end subroutine calc_next_step_implicit

