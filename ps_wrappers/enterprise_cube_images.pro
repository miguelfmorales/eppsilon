pro enterprise_cube_images, folder_names, obs_names_in, data_subdirs=data_subdirs, cube_types = cube_types, $
    pols = pols, evenodd = evenodd, $
    rts = rts, sim = sim, casa = casa, png = png, eps = eps, pdf = pdf, slice_range = slice_range, $
    nvis_norm = nvis_norm, ratio = ratio, diff_ratio = diff_ratio, diff_frac = diff_frac, $
    log = log, data_range = data_range, color_profile = color_profile, sym_color = sym_color, window_num = window_num, plot_as_map = plot_as_map
    
  message, 'Error: This wrapper is depricated and will not continue to be supported. Please call ps_cube_images instead. ' + $
    'This line can be commented out to allow the deprecacated code to run.'
    
  if n_elements(folder_names) gt 2 then message, 'No more than 2 folder_names can be supplied'
  if n_elements(evenodd) eq 0 then evenodd = 'even'
  if n_elements(evenodd) gt 2 then message, 'No more than 2 evenodd values can be supplied'
  if n_elements(obs_names_in) gt 2 then message, 'No more than 2 obs_names can be supplied'
  
  folder_names = enterprise_folder_locs(folder_names, rts = rts)
  
  obs_info = ps_filenames(folder_names, obs_names_in, dirty_folder = dirty_folder, exact_obsnames = exact_obsnames, rts = rts, sim = sim, $
    uvf_input = uvf_input, casa = casa, data_subdirs = data_subdirs, $
    ps_foldernames = ps_foldernames, save_paths = save_paths, plot_paths = plot_paths, refresh_info = refresh_info, no_wtvar_rts = no_wtvar_rts)
    
  if keyword_set(rts) then begin
  
    if obs_info.info_files[0] ne '' then datafile = obs_info.info_files[0] else $
      if obs_info.cube_files.(0)[0] ne '' then datafile = obs_info.cube_files.(0) else $
      datafile = rts_fits2idlcube(obs_info.datafiles.(0), obs_info.weightfiles.(0), obs_info.variancefiles.(0), $
      pol_inc, save_path = obs_info.folder_names[0]+path_sep(), refresh = refresh_dft, no_wtvar = no_wtvar_rts)
      
    if keyword_set(refresh_rtscube) then datafile = rts_fits2idlcube(obs_info.datafiles.(0), obs_info.weightfiles.(0), obs_info.variancefiles.(0), $
      pol_inc, save_path = obs_info.folder_names[0]+path_sep(), /refresh, no_wtvar = no_wtvar_rts)
      
    if keyword_set(no_wtvar_rts) then stop
    
  endif
  
  cube_images, folder_names, obs_info, nvis_norm = nvis_norm, pols = pols, cube_types = cube_types, evenodd = evenodd, rts = rts, $
    png = png, eps = eps, pdf = pdf, slice_range = slice_range, ratio = ratio, diff_ratio = diff_ratio, diff_frac = diff_frac, $
    log = log, data_range = data_range, color_profile = color_profile, sym_color = sym_color, $
    window_num = window_num, plot_as_map = plot_as_map
    
end
