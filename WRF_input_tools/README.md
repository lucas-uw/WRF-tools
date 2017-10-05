# WRF\_input\_tools

## 1. analyze\_namelist.pl
This script helps to translate the parameterization schemes from the coded number to their names. Also it presents a short summary of the WRF configuration. To check the output, just run it with any namelist.input you have:
```sh
$ analyze_namelist.pl -i <path to namelist.input>
```
Below is an example output (for a two-way nested domain)
```sh
[lucas.chen@localhost WRF_input_tools]$ analyze_namelist.pl -i /raid/lucas.chen/lulcc/data/sim.hist/1997CA/NARR/g5/wrf_io/namelist.input 
===========================Time information===========================
Nest 0:
     start from :  1996-12-29  00:00:00 UTC
       run till :  1997-01-05  00:00:00 UTC
      time step :  90  s

Nest 1:
     start from :  1996-12-29  00:00:00 UTC
       run till :  1997-01-05  00:00:00 UTC
      time step :  30  s

Output time step:  60  minute(s)

===========================Space information==========================
Horizontal Resolution:
  Nest 0:
            Grid size :    15000 m x    15000 m
       Grid dimension :      150   x   150
    Vertical Resolution:   35 layers

  Nest 1:
            Grid size :     5000 m x    5000 m
       Grid dimension :      211   x   211
    Vertical Resolution:   35 layers

=======================Parameterication Schemes=======================
                Microphysics :    WSM-5                         WSM-5                     
          Longwave Radiation :    RRTM                          RRTM                      
         Shortwave Radiation :    Dudhia                        Dudhia                    
               Surface Layer :    Rev. MM5                      Rev. MM5                  
                Land Surface :    Noah-MP                       Noah-MP                   
               Urban Surface :    (not used)                    (not used)                
                        Lake :    (Not turned on)           
    Planetary Boundary Layer :    Yonsei Univ.                  Yonsei Univ.              
                     Cumulus :    Grell-Freitas                 (not used)
          Shallow Convection :    (Not turned on)           
```

Also you can find out more on its usage by running:
```sh
$ analyze_namelist.pl
```
Note this version currently support WRF v3.6.x. So you may want to double check the hashes in the script with WRF user guide to make sure the coding of each parameterization scheme has the same meaning, and modify them when different. I am not responsible for any mistakes from using this script to check your namelist.input.

## 2. Visualize\_WPS\_domain.ipynb
This is to help visualize the WRF spatial domain from the WPS input (i.e. namelist.wps). You can find more on this script at [my blog post](https://wolfscie.wordpress.com/2017/10/05/visualizing-wrf-domain/). It contains some wheel functions that you can use for other purposes.




