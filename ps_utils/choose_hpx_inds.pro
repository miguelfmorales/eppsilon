pro choose_hpx_inds, cube_file, inds_save_file, default_size_multiple = default_size_multiple, $
    hubble_param = hubble_param, show_plot = show_plot
    
  ; inds_save_file='~/EoR0_low_healpix_inds.idlsave'
    
  if n_elements(default_size_multiple) eq 0 then default_size_multiple = 1
  
  default_size_meters = 4.5 ;use 4.5m to be conservative
  size_use_meters = default_size_meters / default_size_multiple
  
  pixel_nums1 = getvar_savefile(cube_file, 'hpx_inds')
  nside = getvar_savefile(cube_file, 'nside')
  obs = getvar_savefile(cube_file, 'obs')
  frequencies = findgen(obs.n_freq,start=obs.freq_center-(obs.n_freq/2)*obs.freq_res,increment=obs.freq_res)
  
  z_mpc_mean = z_mpc(frequencies, hubble_param = hubble_param)
  
  ;; get pixel vectors
  pix2vec_ring, nside, pixel_nums1, pix_center_vec
  ;; find mid point (work in x/y because of possible jumps in phi)
  vec_mid = [mean(pix_center_vec[*,0]), mean(pix_center_vec[*,1]), mean(pix_center_vec[*,2])]
  theta0 = acos(vec_mid[2])
  phi0 = atan(vec_mid[1], vec_mid[0])
  
  ;; To go to flat sky, rotate patch to zenith and flatten.
  ;; To get to current location, need to first rotate around z by
  ;; phi, then around y by -theta, then around z by -phi
  ;; use inverse to rotate back to zenith
  rot_matrix = get_rot_matrix(theta0, phi0, /inverse)
  new_pix_vec = rot_matrix ## pix_center_vec
  
  ;; adjust to actually center these
  x_nudge = mean(new_pix_vec[*,0])
  y_nudge = mean(new_pix_vec[*,1])
  
  new_pix_vec[*,0] = new_pix_vec[*,0] - x_nudge
  new_pix_vec[*,1] = new_pix_vec[*,1] - y_nudge
  
  ;; then rotate to make as rectangular as possible
  pred_angle = healpix_rot(new_pix_vec[*,0], new_pix_vec[*,1])
  
  x_rot = new_pix_vec[*,0] * cos(pred_angle) - new_pix_vec[*,1] * sin(pred_angle)
  y_rot = new_pix_vec[*,0] * sin(pred_angle) + new_pix_vec[*,1] * cos(pred_angle)
  
  kperp_lambda_conv = z_mpc_mean / (2.*!pi)
  
  consv_delta_kperp_rad = size_use_meters * mean(frequencies) * z_mpc_mean / (3e8 * kperp_lambda_conv)
  consv_xy_len = 2*!pi/consv_delta_kperp_rad
  radius = consv_xy_len/2.*sqrt(2)*1.1
  query_disc, nside, vec_mid, radius, listpix, nlist, /inc
  
  pix2vec_ring, nside, listpix, list_center_vec
  new_list_vec = rot_matrix ## list_center_vec
  
  new_list_vec[*,0] = new_list_vec[*,0] - x_nudge
  new_list_vec[*,1] = new_list_vec[*,1] - y_nudge
  
  x_list_rot = new_list_vec[*,0] * cos(pred_angle) - new_list_vec[*,1] * sin(pred_angle)
  y_list_rot = new_list_vec[*,0] * sin(pred_angle) + new_list_vec[*,1] * cos(pred_angle)
  
  if keyword_set(show_plot) then cgplot, x_list_rot, y_list_rot, psym=3
  
  consv_lims = [-1*consv_xy_len/2., -1*consv_xy_len/2., consv_xy_len/2., consv_xy_len/2.]
  if keyword_set(show_plot) then cgpolygon, reform(rebin(consv_lims[[0,2]], 2,2),4), reform(rebin(reform(consv_lims[[1,3]],1,2), 2,2),4), color='aqua'
  wh_listpix_close = where(x_list_rot ge consv_lims[0] and x_list_rot le consv_lims[2] and $
    y_list_rot ge consv_lims[1] and y_list_rot le consv_lims[3], count_list_close)
  hpx_inds = listpix[wh_listpix_close]
  nside = nside
  
  print, 'number of pixels selected: ', number_formatter(count_list_close)
  
  save, file=inds_save_file, nside, hpx_inds
  
end
