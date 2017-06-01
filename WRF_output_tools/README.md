# README
Disclaimer: All these scripts/codes are developped for use in my research project. I have tested them with various inputs in my case, however this does not guarantee that they would also work in your case. If you have any questions, please feel free to file an issue here, and I will try to help get it done.

### 1. collect_wrf_rainfall.pl
 This script collects total precipitation (i.e. RAINC+RAINNC) from WRF output files wrfout_d*. Currently it only handles d01 domain.
 The total precipitation is stored as RAIN variable in the output file


### 2. Add_cdo_info_to_wrfout.d01.py

Most of the remapping (presumably in Climate Data Operator CDO) uses only the distance info of target point to the reference point, so these remapping can be directly applied to the WRF output (wrfout_d*). For __precipitation__, however, it is often required to do a conservation remapping. In this situation, along with the lat/lon info we also need to know the corner lat/lon of each grid (so area of the grid can be calculate by CDO). This script extracts precipitation data, and adds the corner information to the WRF output. In my case, this script is required for Lambert Conformal Conic projection and Mercator projection. For other projections, I am not sure if CDO could recognize the projection (so this script is no longer needed).

Before running this script, a special WPS run (more specifically, only geogrid.exe) is required. Below shows the modifications needed, basically we use half-size grids (i.e. 15km to 7.5km) to cover the same domain (so at each direction we need to double the grid number).
- namelist.wps for the WRF simulation:
  e_we          = 80,
  e_sn          = 80,
  dx            = 15000,
  dy            = 15000,
- namelist.wps for this special run:
  e_we          = 160,
  e_sn          = 160,
  dx            = 7500,
  dy            = 7500,

Then supply the generated geo_em.d01.nc to this script. All other inputs are explained when you run the script without any input argument.

### 3. Add_cdo_info_to_wrfout.d0x.py
This script provides the same function as its d01 brother. However, to accommodate the nested domain, the namelist.wps need to be modified in a different way:

- note here it has only one nested domain. For multiple domains, just focus on the nested domain level you need and its parenet level.
- namelist.wps for the WRF simulation:
  parent_id         = 1,1
  parent_grid_ratio = 1,__3__
  i_parent_start    = 1,__40__
  j_parent_start    = 1,__35__
  e_we              = 150,__211__
  e_sn              = 140,__211__
  geog_data_res     = '2m','30s'
  dx                = 15000,
  dy                = 15000,

- namelist.wps for the special run:
  parent_id         = 1,1
  parent_grid_ratio = 1,__6__
  i_parent_start    = 1,__39__
  j_parent_start    = 1,__34__
  e_we              = 150,__481__
  e_sn              = 140,__481__
  geog_data_res     = '2m', '30s'
  dx                = 15000,
  dy                = 15000,

The basic idea is to reduce the grid size in the desired domain (by doubleing the grid_ratio). The grid number needs to be at least doubled (so here e_we needs to be larger than 211**2=422), also it still needs to satisfy WPS requirement (i.e. 3*int+1), so here I went with 481.You can also use something like 451 here. Also reduce the i_parent and j_parent start index by 1. This has to be always 1, otherwise you need to change the parameter in the script.
