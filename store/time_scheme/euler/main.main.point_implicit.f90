part_primitive
      call set_dt(i)
part_point_implicit

      qp = q
part_primitive
part_main
      call calc_next_step
