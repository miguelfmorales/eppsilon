#! /bin/bash
#integrate cubes and run Bryna's PS code
#$ -V
#$ -N PS_B
#$ -S /bin/bash

#inputs needed: file_path_cubes, obs_list_path, version, nslots

echo JOBID ${JOB_ID}

(( nperint = $nslots/2 ))

# Get list of obs to integrate, turn them into file names to integrate
even_file_paths=${file_path_cubes}/${version}_even_list.txt
odd_file_paths=${file_path_cubes}/${version}_odd_list.txt
# clear file paths
rm $even_file_paths
rm $odd_file_paths
nobs=0
while read line
do
  even_file=${file_path_cubes}/${line}_even_cube.sav
  odd_file=${file_path_cubes}/${line}_odd_cube.sav
  echo $even_file >> $even_file_paths
  echo $odd_file >> $odd_file_paths
  ((nobs++))
done < $obs_list_path

#Integrate cubes
unset int_pids

save_file="$file_path_cubes"/Healpix/Combined_obs_${version}_even_cube.sav
/usr/local/bin/idl -IDL_DEVICE ps -IDL_CPU_TPOOL_NTHREADS $nperint -e integrate_healpix_cubes -args "$even_file_paths" "$save_file" &
int_pids+=( $! )
save_file="$file_path_cubes"/Healpix/Combined_obs_${version}_odd_cube.sav
/usr/local/bin/idl -IDL_DEVICE ps -IDL_CPU_TPOOL_NTHREADS $nperint -e integrate_healpix_cubes -args "$odd_file_paths" "$save_file" &
int_pids+=( $! )
wait ${int_pids[@]} # Wait for integration to finish before making PS

#Make power spectra through a ps wrapper in idl

input_file=${file_path_cubes}/
idl -IDL_DEVICE ps -IDL_CPU_TPOOL_NTHREADS $nslots -e mit_ps_job -args $input_file $version $nobs

