#!/usr/bin/python

import numpy as np
import netCDF4 as nc
import sys

def print_help():
	print '  Add_cdo_info_to_wrfout.d0x.py: Add necessary information to the WRF output, so that the coordinate system (LCC) can be recognized by CDO `cdo sinfo`. Only for nested domains.'
	print '  Ver:     1.0.0'
	print '  Author:  Xiaodong Chen  <xiaodc.work@gmail.com>\n'
	print '  Use: Add_cdo_info_to_wrfout.d02.py <geoinfo_file> <wrffile> <outfile> <start_date> <start_hour> <frames>\n'
	print '         <geoinfo_file>    geogrid.exe output containing the half-resolution grids information'
	print '                           e.g. For 15km grids, it contains the 7.5km grids info'
	print '                           Generate it from a seperate WPS/geogrid.exe run, with same namelist.wps but only half dx and dy, doubled e_we and e_sn\n'
	print '         <wrffile>         WRF variable data after priliminary post-processing, or WRF output (i.e. wrfout_d02* file)'
        print '                            Basic structure from `ncks -v XLAT,XLONG,RAINC,RAINNC  wrfout_d01.xxxx  yyyyR.nc;ncrcat yyyy1.nc yyyy2.nc <wrffile>`'
        print '                            Should contain at least XLAT, XLONG, RAINC, RAINNC. Can be in single time snap or multiple snaps\n'
	print '         <outfile>         Output file name\n'
	print '         <start_date>      The first date in the <wrffile>.\n'
	print '         <start_hour>      The first hour in the <wrffile>.\n'
        print '         <frames>          Total time steps in the WRF output. Obtained by "ncdump -h"\n'



if len(sys.argv)==1:
        print_help()
	exit()
	
geoinfo_file = sys.argv[1] # e.g. '/raid/xiaodong.chen/lulcc/data/sim.hist/1997CA/wps_io/geo_em.half_grids.d01.nc'
wrffile = sys.argv[2] # e.g. '/raid/xiaodong.chen/lulcc/data/sim.hist/1997CA/rtot1h/rainfall_15km_1hr/regrid_test/rainfall_ncep2_1_1.nc'
outfile = sys.argv[3] # e.g. '/raid/xiaodong.chen/lulcc/data/sim.hist/1997CA/rtot1h/rainfall_15km_1hr/regrid_test/rainfall_ncep2_1_1.cdo_ready.nc'
start_date = sys.argv[4] # e.g.  1996-12-29
start_hour = sys.argv[5] # e.g. 0
frames = sys.argv[5]

offset = 4   # This is obtained by the "plot_WRF_lambert_points.ipynb" script

rootgroup = nc.Dataset(geoinfo_file,'r',format='NETCDF4')
lat_matrix_half = rootgroup.variables['XLAT_M'][0,:]
lon_matrix_half = rootgroup.variables['XLONG_M'][0,:]
rootgroup.close()

ingroup = nc.Dataset(wrffile,'r',format='NETCDF4')
lat_matrix = ingroup.variables['XLAT'][0,:]
lon_matrix = ingroup.variables['XLONG'][0,:]
rainnc = ingroup.variables['RAINNC'][:]
rainc = ingroup.variables['RAINC'][:]
ingroup.close()
nx = lat_matrix.shape[0]
ny = lat_matrix.shape[1]

outgroup = nc.Dataset(outfile,'w',format='NETCDF4')
xdim = outgroup.createDimension('x',nx)
ydim = outgroup.createDimension('y',ny)
verdim = outgroup.createDimension('vertices',4)
timedim = outgroup.createDimension('time',None)

# Find the grid corner info
lat_center = np.zeros((nx,ny))
lat_ll = np.zeros((nx,ny))
lat_lr = np.zeros((nx,ny))
lat_ur = np.zeros((nx,ny))
lat_ul = np.zeros((nx,ny))

lon_center = np.zeros((nx,ny))
lon_ll = np.zeros((nx,ny))
lon_lr = np.zeros((nx,ny))
lon_ur = np.zeros((nx,ny))
lon_ul = np.zeros((nx,ny))

for i in np.arange(nx):
	for j in np.arange(ny):
		lat_center[i,j] = lat_matrix[i,j]
		lat_ll[i,j] = (lat_matrix_half[i*2+1+offset,j*2+1+offset] + lat_matrix_half[i*2+1+offset,j*2+2+offset] + lat_matrix_half[i*2+2+offset,j*2+2+offset] + lat_matrix_half[i*2+2+offset,j*2+1+offset])/4   # lat_matrix_half[i*2+offset,j*2]
		lat_lr[i,j] = (lat_matrix_half[i*2+1+offset,j*2+3+offset] + lat_matrix_half[i*2+1+offset,j*2+4+offset] + lat_matrix_half[i*2+2+offset,j*2+4+offset] + lat_matrix_half[i*2+2+offset,j*2+3+offset])/4   # lat_matrix_half[i*2+offset,j*2+2]
		lat_ur[i,j] = (lat_matrix_half[i*2+3+offset,j*2+3+offset] + lat_matrix_half[i*2+3+offset,j*2+4+offset] + lat_matrix_half[i*2+4+offset,j*2+4+offset] + lat_matrix_half[i*2+4+offset,j*2+3+offset])/4   # lat_matrix_half[i*2+2+offset,j*2+2]
		lat_ul[i,j] = (lat_matrix_half[i*2+3+offset,j*2+1+offset] + lat_matrix_half[i*2+3+offset,j*2+2+offset] + lat_matrix_half[i*2+4+offset,j*2+2+offset] + lat_matrix_half[i*2+4+offset,j*2+1+offset])/4   # lat_matrix_half[i*2+2+offset,j*2]
        
		lon_center[i,j] = lon_matrix[i,j]
		lon_ll[i,j] = (lon_matrix_half[i*2+1+offset,j*2+1+offset] + lon_matrix_half[i*2+1+offset,j*2+2+offset] + lon_matrix_half[i*2+2+offset,j*2+2+offset] + lon_matrix_half[i*2+2+offset,j*2+1+offset])/4   # lon_matrix_half[i*2+offset,j*2]
		lon_lr[i,j] = (lon_matrix_half[i*2+1+offset,j*2+3+offset] + lon_matrix_half[i*2+1+offset,j*2+4+offset] + lon_matrix_half[i*2+2+offset,j*2+4+offset] + lon_matrix_half[i*2+2+offset,j*2+3+offset])/4   # lon_matrix_half[i*2+offset,j*2+2]
		lon_ur[i,j] = (lon_matrix_half[i*2+3+offset,j*2+3+offset] + lon_matrix_half[i*2+3+offset,j*2+4+offset] + lon_matrix_half[i*2+4+offset,j*2+4+offset] + lon_matrix_half[i*2+4+offset,j*2+3+offset])/4   # lon_matrix_half[i*2+2+offset,j*2+2]
		lon_ul[i,j] = (lon_matrix_half[i*2+3+offset,j*2+1+offset] + lon_matrix_half[i*2+3+offset,j*2+2+offset] + lon_matrix_half[i*2+4+offset,j*2+2+offset] + lon_matrix_half[i*2+4+offset,j*2+1+offset])/4   # lon_matrix_half[i*2+2+offset,j*2]


# Add variables, notice the xxxxx.coordinates
time_var = outgroup.createVariable('time','i4',('time'))
time_var.units = 'hours since '+ start_date + ' ' + '%02d'%(int(start_hour)) + ':00:00 UTC'
time_var.calendar = 'gregorian'

lat_var = outgroup.createVariable('lat','f8',('x','y'))
lat_var.stand_name = 'latitude'
lat_var.long_name = 'latitude'
lat_var.units = 'degrees_north'
lat_var.bounds = 'lat_vertices'

lon_var = outgroup.createVariable('lon','f8',('x','y'))
lon_var.stand_name = 'longitude'
lon_var.long_name = 'longitude'
lon_var.units = 'degrees_east'
lon_var.bounds = 'lon_vertices'

rainnc_var = outgroup.createVariable('RAINNC','f8',('time','x','y'))
rainnc_var.longname = 'ACCUMULATED TOTAL GRID SCALE PRECIPITATION'
rainnc_var.units = 'mm'
rainnc_var.coordinates = 'lat lon'

rainc_var = outgroup.createVariable('RAINC','f8',('time','x','y'))
rainc_var.longname = 'ACCUMULATED TOTAL CUMULUS PRECIPITATION'
rainc_var.units = 'mm'
rainc_var.coordinates = 'lat lon'

latver_var = outgroup.createVariable('lat_vertices','f8',('x','y','vertices'))
lonver_var = outgroup.createVariable('lon_vertices','f8',('x','y','vertices'))

time_var[:] = np.arange(int(frames))
lat_var[:] = lat_center
lon_var[:] = lon_center
rainnc_var[:] = rainnc
rainc_var[:] = rainc

latver_var[:,:,0] = lat_ll
latver_var[:,:,1] = lat_lr
latver_var[:,:,2] = lat_ur
latver_var[:,:,3] = lat_ul

lonver_var[:,:,0] = lon_ll
lonver_var[:,:,1] = lon_lr
lonver_var[:,:,2] = lon_ur
lonver_var[:,:,3] = lon_ul

outgroup.close()
