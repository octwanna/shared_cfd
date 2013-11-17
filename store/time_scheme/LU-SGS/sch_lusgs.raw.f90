subroutine set_ABpm
   use grbl_prmtr
   use mod_mpi
   use variable
   use var_lusgs

   implicit none
   double precision rho,u,v,H,c,p,Vs
   double precision tmp
   double precision unA, unB, nuA, nuB
   double precision,dimension(dimq,dimq)::A,B,Atilde,Btilde
   double precision,dimension(dimq)::tA,tB
   double precision gmmad,gamm
   integer i,j,k,l

   !$omp parallel do private(i,k,l,&
   !$omp                     rho,u,v,H,Vs,&
   !$omp                     p,c,tmp,&
   !$omp                     unA,unB,nuA,nuB,&
   !$omp                     A,B,Atilde,Btilde,&
   !$omp                     gmmad,gamm,&
   !$omp                     tA,tB)
   do j=nys,nye
      do i=nxs,nxe
         !set w
         rho  = w(     1,i,j)
         u    = w(     2,i,j)
         v    = w(     3,i,j)
         p    = w(     4,i,j)
         gamm = w(indxg ,i,j)
         H    = w(indxht,i,j)
         c    = sqrt(gamm*p/rho)
         gmmad= gamm-1d0
         Vs   = u**2+v**2

         !unA,unB,nuA,nuB
         unA=vnci(1,i,j)*u+vnci(2,i,j)*v
         unB=vncj(1,i,j)*u+vncj(2,i,j)*v
         nuA = abs(unA)+c
         nuB = abs(unB)+c
        
         !set A
         A(nY+1,nY+1)= u*(3d0-gamm)
         A(nY+2,nY+1)= v
         A(nY+3,nY+1)= H-u**2*gmmad

         A(nY+1,nY+2)=-v*gmmad
         A(nY+2,nY+2)= u
         A(nY+3,nY+2)=-u*v*gmmad

         A(nY+1,nY+3)= gmmad
         A(nY+2,nY+3)= 0d0
         A(nY+3,nY+3)= u*gamm

         !set tA
         do k=1,nY
            tA(k)     =-w(4+k,i,j)*u
            A( k,nY+1)= w(4+k,i,j)
            A( k,nY+2)= 0d0
            A( k,nY+3)= 0d0
         end do
         tA(nY+1)=-u**2 +0.5d0*gmmad*Vs
         tA(nY+2)=-u*v
         tA(nY+3)= u*(-H+0.5d0*gmmad*Vs)

         !set B
         B(nY+1,nY+1)= 0d0
         B(nY+1,nY+2)= 1d0
         B(nY+1,nY+3)= 0d0

         B(nY+1,nY+1)= v
         B(nY+2,nY+1)=-u*gmmad
         B(nY+3,nY+1)=-u*v*gmmad

         B(nY+1,nY+2)= u
         B(nY+2,nY+2)= v*(3d0-gamm)
         B(nY+3,nY+2)= H-v**2*gmmad

         B(nY+1,nY+3)= 0d0
         B(nY+2,nY+3)= gmmad
         B(nY+3,nY+3)= v*gamm

         !set tB
         do k=1,nY
            tB(k)     =-w(4+k,i,j)*v
            B( k,nY+1)= 0d0
            B( k,nY+2)= w(4+k,i,j)
            B( k,nY+3)= 0d0
         end do
         tB(nY+1)=-v*u
         tB(nY+2)=-v**2 +0.5d0*gmmad*Vs
         tB(nY+3)= v*(-H+0.5d0*gmmad*Vs)

         do k=1,nY
            do l=1,nY
               A(l,k)=tA(l)
               B(l,k)=tB(l)
            end do

            A(k   ,k)=tA(k   )+u
            A(nY+1,k)=tA(nY+1)+DHi(k,i,j)
            A(nY+2,k)=tA(nY+2)
            A(nY+3,k)=tA(nY+3)+DHi(k,i,j)*u

            B(k   ,k)=tB(k   )+v
            B(nY+1,k)=tB(nY+1)
            B(nY+2,k)=tB(nY+2)+DHi(k,i,j)
            B(nY+3,k)=tB(nY+3)+DHi(k,i,j)*v
         end do

         !set Atilde, Apm
         Atilde = vnci(1,i,j)*A+vnci(2,i,j)*B

         Ap(:,:,i,j)= Atilde*0.5d0
         Am(:,:,i,j)= Atilde*0.5d0

         do k=1,dimq
            Ap(k,k,i,j)=Ap(k,k,i,j)+nuA*0.5d0
            Am(k,k,i,j)=Am(k,k,i,j)-nuA*0.5d0
         end do

         !set Btilde, Bpm
         Btilde= vncj(1,i,j)*A+vncj(2,i,j)*B

         Bp(:,:,i,j)= Btilde*0.5d0
         Bm(:,:,i,j)= Btilde*0.5d0

         do k=1,dimq
            Bp(k,k,i,j)=Bp(k,k,i,j)+nuB*0.5d0
            Bm(k,k,i,j)=Bm(k,k,i,j)-nuB*0.5d0
         end do

         !set alpha
         tmp= Vol(i,j)/DT_LOCAL_GLOBAL + dsci(i,j)*nuA+dscj(i,j)*nuB
         alpha(i,j)=1d0/tmp
      end do
   end do
   !$omp end parallel do
end subroutine set_ABpm

subroutine set_vnc_dsc
   use grbl_prmtr
   use mod_mpi
   use variable
   use var_lusgs
   implicit none
   double precision,dimension(2)::a,b,c,d
   integer i,j

   do j=nys,nye
      do i=nxs,nxe
         a(1)=(xh(i-1,j-1)+xh(i,j-1))*0.5d0
         a(2)=(rh(i-1,j-1)+rh(i,j-1))*0.5d0
         b(1)=(xh(i,j-1)  +xh(i,j)  )*0.5d0
         b(2)=(rh(i,j-1)  +rh(i,j)  )*0.5d0
         c(1)=(xh(i-1,j)  +xh(i,j)  )*0.5d0
         c(2)=(rh(i-1,j)  +rh(i,j)  )*0.5d0
         d(1)=(xh(i-1,j-1)+xh(i-1,j))*0.5d0
         d(2)=(rh(i-1,j-1)+rh(i-1,j))*0.5d0
         dsci(i,j)=sqrt((c(1)-a(1))**2+(c(2)-a(2))**2)
         dscj(i,j)=sqrt((b(1)-d(1))**2+(b(2)-d(2))**2)
         vnci(1,i,j)=(b(1)-d(1))/dscj(i,j)
         vnci(2,i,j)=(b(2)-d(2))/dscj(i,j)
         vncj(1,i,j)=(c(1)-a(1))/dsci(i,j)
         vncj(2,i,j)=(c(2)-a(2))/dsci(i,j)

         !!only when cylindrical
         !dsci(i,j)=dsci(i,j)*(c(2)+a(2))*0.5d0
         !dscj(i,j)=dscj(i,j)*(b(2)+d(2))*0.5d0
      end do
   end do
end subroutine set_vnc_dsc
