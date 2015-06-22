pro ps_power, file_struct, refresh = refresh, kcube_refresh = kcube_refresh, dft_refresh_data = dft_refresh_data, $
    dft_refresh_weight = dft_refresh_weight, refresh_beam = refresh_beam, $
    savefile_2d = savefile_2d, savefile_1d = savefile_1d, hinv = hinv, $
    savefile_kpar_power = savefile_kpar_power, savefile_kperp_power = savefile_kperp_power, savefile_k0 = savefile_k0, $
    dft_ian = dft_ian, cut_image = cut_image, $
    uvf_input = uvf_input, uv_avg = uv_avg, uv_img_clip = uv_img_clip, sim=sim, $
    dft_fchunk = dft_fchunk, freq_ch_range = freq_ch_range, freq_flags = freq_flags, $
    spec_window_type = spec_window_type, delta_uv_lambda = delta_uv_lambda, max_uv_lambda = max_uv_lambda, $
    std_power = std_power, inverse_covar_weight = inverse_covar_weight, no_wtd_avg = no_wtd_avg, $
    no_kzero = no_kzero, log_kpar = log_kpar, $
    log_kperp = log_kperp, kperp_bin = kperp_bin, kpar_bin = kpar_bin, log_k1d = log_k1d, k1d_bin = k1d_bin, $
    kperp_range_1dave = kperp_range_1dave, kperp_range_lambda_1dave = kperp_range_lambda_1dave, kpar_range_1dave = kpar_range_1dave, $
    wt_measures = wt_measures, wt_cutoffs = wt_cutoffs, fix_sim_input = fix_sim_input, $
    wedge_amp = wedge_amp, coarse_harm0 = coarse_harm0, coarse_width = coarse_width, $
    input_units = input_units, fill_holes = fill_holes, quiet = quiet, no_dft_progress = no_dft_progress
    
  if tag_exist(file_struct, 'nside') ne 0 then healpix = 1 else healpix = 0
  ;refresh=1
  nfiles = n_elements(file_struct.datafile)
  
  if healpix and (keyword_set(dft_refresh_data) or keyword_set(dft_refresh_weight)) then kcube_refresh=1
  if keyword_set(refresh_beam) then kcube_refresh = 1
  if keyword_set(kcube_refresh) then refresh = 1
  
  if n_elements(fill_holes) eq 0 then fill_holes = 0
  
  if n_elements(freq_flags) ne 0 then freq_mask = file_struct.freq_mask
  
  test_powersave = file_test(file_struct.power_savefile) *  (1 - file_test(file_struct.power_savefile, /zero_length))
  
  if test_powersave eq 1 and n_elements(freq_flags) ne 0 then begin
    old_freq_mask = getvar_savefile(file_struct.power_savefile, 'freq_mask')
    if total(abs(old_freq_mask - freq_mask)) ne 0 then test_powersave = 0
  endif
  
  if test_powersave eq 0 or keyword_set(refresh) then begin
  
    test_kcube = file_test(file_struct.kcube_savefile) *  (1 - file_test(file_struct.kcube_savefile, /zero_length))
    
    if test_kcube eq 1 and n_elements(freq_flags) ne 0 then begin
      old_freq_mask = getvar_savefile(file_struct.kcube_savefile, 'freq_mask')
      if total(abs(old_freq_mask - freq_mask)) ne 0 then test_kcube = 0
    endif
    
    if test_kcube eq 0 or keyword_set(kcube_refresh) then $
      ps_kcube, file_struct, dft_refresh_data = dft_refresh_data, dft_refresh_weight = dft_refresh_weight, refresh_beam = refresh_beam, $
      dft_ian = dft_ian, dft_fchunk = dft_fchunk, freq_ch_range = freq_ch_range, freq_flags = freq_flags, $
      cut_image = cut_image, delta_uv_lambda = delta_uv_lambda, max_uv_lambda = max_uv_lambda, $
      uvf_input = uvf_input, uv_avg = uv_avg, uv_img_clip = uv_img_clip, sim=sim, fix_sim_input = fix_sim_input, $
      spec_window_type = spec_window_type, std_power = std_power, inverse_covar_weight = inverse_covar_weight, $
      input_units = input_units, no_dft_progress = no_dft_progress
      
    if nfiles eq 1 then begin
      restore, file_struct.kcube_savefile
      
      n_kx = n_elements(kx_mpc)
      n_ky = n_elements(ky_mpc)
      n_kz = n_elements(kz_mpc)
      
      ;; now construct weights for power (mag. squared) = 1/power variance
      power_weights1 = 1d/(4*(sigma2_1)^2d)
      wh_sig1_0 = where(sigma2_1^2d eq 0, count_sig1_0)
      if count_sig1_0 ne 0 then power_weights1[wh_sig1_0] = 0
      undefine, sigma2_1
      
      power_weights2 = 1d/(4*(sigma2_2)^2d) ;; inverse variance
      wh_sig2_0 = where(sigma2_2^2d eq 0, count_sig2_0)
      if count_sig2_0 ne 0 then power_weights2[wh_sig2_0] = 0
      undefine, sigma2_2
      
      if keyword_set(no_wtd_avg) then begin
        term1 = abs(data_sum_1)^2.
        term2 = abs(data_sum_2)^2.
        undefine, data_sum_1, data_sum_2
        
        weights_3d = (power_weights1 + power_weights2)
        undefine, power_weights1, power_weights2
        
        ;; expected noise is just sqrt(variance)
        noise_expval_3d = 1./sqrt(weights_3d)
        
        ;; Add the 2 terms
        power_3d = (term1 + term2)
        undefine, term1, term2
        
        wh_wt0 = where(weights_3d eq 0, count_wt0)
        if count_wt0 ne 0 then begin
          power_3d[wh_wt0] = 0
          noise_expval_3d[wh_wt0] = 0
        endif
        
      endif else begin
        term1 = abs(data_sum_1)^2.*power_weights1
        term2 = abs(data_sum_2)^2.*power_weights2
        undefine, data_sum_1, data_sum_2
        
        ;; Factor of 2 because we're adding the cosine & sine terms
        noise_expval_3d = (sqrt(power_weights1 + power_weights2))*2.
        ;; except for kparallel=0 b/c there's only one term
        noise_expval_3d[*,*,0] = noise_expval_3d[*,*,0]/2.
        
        weights_3d = (power_weights1 + power_weights2)
        undefine, power_weights1, power_weights2
        
        ;; multiply by 2 because power is generally the SUM of the cosine & sine powers
        power_3d = (term1 + term2)*2.
        ;; except for kparallel=0 b/c there's only one term
        power_3d[*,*,0] = power_3d[*,*,0]/2.
        
        power_3d = power_3d / weights_3d
        noise_expval_3d = noise_expval_3d / weights_3d
        undefine, term1, term2
        
        wh_wt0 = where(weights_3d eq 0, count_wt0)
        if count_wt0 ne 0 then begin
          power_3d[wh_wt0] = 0
          noise_expval_3d[wh_wt0] = 0
        endif
        
        ;; variance_3d = 4/weights_3d b/c of factors of 2 in power
        ;; in later code variance is taken to be 1/weights so divide by 4 now
        weights_3d = weights_3d/4.
        ;; except for kparallel=0 b/c there's only one term
        weights_3d[*,*,0] = weights_3d[*,*,0]*4.
      endelse
      
      
    endif else begin
      ;; nfiles=2
      restore, file_struct.kcube_savefile
      n_kx = n_elements(kx_mpc)
      n_ky = n_elements(ky_mpc)
      n_kz = n_elements(kz_mpc)
      
      ;; now construct weights for power (mag. squared) = 1/power variance
      power_weights1 = 1d/(4*(sigma2_1)^2d)
      wh_sig1_0 = where(sigma2_1^2d eq 0, count_sig1_0)
      if count_sig1_0 ne 0 then power_weights1[wh_sig1_0] = 0
      undefine, sigma2_1
      
      power_weights2 = 1d/(4*(sigma2_2)^2d) ;; inverse variance
      wh_sig2_0 = where(sigma2_2^2d eq 0, count_sig2_0)
      if count_sig2_0 ne 0 then power_weights2[wh_sig2_0] = 0
      undefine, sigma2_1
      
      if keyword_set(no_wtd_avg) then begin
        term1 = (abs(data_sum_1)^2. - abs(data_diff_1)^2.)
        term2 = (abs(data_sum_2)^2. - abs(data_diff_2)^2.)
        undefine, data_sum_1, data_sum_2
        
        noise_t1 = abs(data_diff_1)^2.
        noise_t2 = abs(data_diff_2)^2.
        undefine, data_diff_1, data_diff_2
        
        weights_3d = power_weights1 + power_weights2
        undefine, power_weights1, power_weights2
        
        ;; expected noise is just sqrt(variance)
        noise_expval_3d = 1./sqrt(weights_3d)
        
        ;; Add the 2 terms
        power_3d = (term1 + term2)
        noise_3d = (noise_t1 + noise_t2)
        undefine, term1, term2, noise_t1, noise_t2
        
        wh_wt0 = where(weights_3d eq 0, count_wt0)
        if count_wt0 ne 0 then begin
          power_3d[wh_wt0] = 0
          noise_expval_3d[wh_wt0] = 0
          noise_3d[wh_wt0] = 0
        endif
        
      endif else begin
        term1 = (abs(data_sum_1)^2. - abs(data_diff_1)^2.) * power_weights1
        term2 = (abs(data_sum_2)^2. - abs(data_diff_2)^2.) * power_weights2
        undefine, data_sum_1, data_sum_2
        
        noise_t1 = abs(data_diff_1)^2. * power_weights1
        noise_t2 = abs(data_diff_2)^2. * power_weights2
        undefine, data_diff_1, data_diff_2
        
        ;; Factor of 2 because we're adding the cosine & sine terms
        noise_expval_3d = sqrt(power_weights1 + power_weights2)*2
        ;; except for kparallel=0 b/c there's only one term
        noise_expval_3d[*,*,0] = noise_expval_3d[*,*,0]/2.
        
        
        weights_3d = power_weights1 + power_weights2
        undefine, power_weights1, power_weights2
        
        ;; divide by 4 on power b/c otherwise it would be 4*Re(even-odd crosspower)
        ;power_3d = (term1 + term2) / (4. * weights_3d)
        ;; Actually the 4*crosspower is what we want, see Adam's memo
        ;; multiply by 2 because power is generally the SUM of the cosine & sine powers
        power_3d = (term1 + term2)*2.
        noise_3d = (noise_t1 + noise_t2)*2
        ;; except for kparallel=0 b/c there's only one term
        power_3d[*,*,0] = power_3d[*,*,0]/2.
        noise_3d[*,*,0] = noise_3d[*,*,0]/2.
        
        power_3d = power_3d / weights_3d
        noise_3d = noise_3d / weights_3d
        noise_expval_3d = noise_expval_3d / weights_3d
        undefine, term1, term2, noise_t1, noise_t2
        
        wh_wt0 = where(weights_3d eq 0, count_wt0)
        if count_wt0 ne 0 then begin
          power_3d[wh_wt0] = 0
          noise_expval_3d[wh_wt0] = 0
          noise_3d[wh_wt0] = 0
        endif
        
        ;; variance_3d = 4/weights_3d b/c of factors of 2 in power
        ;; in later code variance is taken to be 1/weights so divide by 4 now
        weights_3d = weights_3d/4.
        ;; except for kparallel=0 b/c there's only one term
        weights_3d[*,*,0] = weights_3d[*,*,0]*4.
      endelse
      
    endelse
    
    git, repo_path = ps_repository_dir(), result=ps_git_hash
    if n_elements(git_hashes) gt 0 then git_hashes = create_struct(git_hashes, 'ps', ps_git_hash) $
    else git_hashes = {uvf:strarr(nfiles), uvf_wt:strarr(nfiles), beam:strarr(nfiles), kcube:'', ps:ps_git_hash}
    
    if n_elements(freq_flags) ne 0 then begin
      save, file = file_struct.power_savefile, power_3d, noise_3d, noise_expval_3d, weights_3d, $
        kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param, n_freq_contrib, freq_mask, $
        vs_name, vs_mean, t_sys_meas, window_int, git_hashes, $
        wt_meas_ave, wt_meas_min, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf
    endif else begin
      save, file = file_struct.power_savefile, power_3d, noise_3d, noise_expval_3d, weights_3d, $
        kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param, n_freq_contrib, $
        vs_name, vs_mean, t_sys_meas, window_int, git_hashes, $
        wt_meas_ave, wt_meas_min, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf
    endelse
    
    write_ps_fits, file_struct.fits_power_savefile, power_3d, weights_3d, noise_expval_3d, noise_3d = noise_3d, $
      kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param
      
  endif else restore, file_struct.power_savefile
  
  print, 'power integral:', total(power_3d)
  
  wt_ave_power = total(weights_3d * power_3d)/total(weights_3d)
  ave_power = mean(power_3d[where(weights_3d ne 0)])
  
  n_kx = n_elements(kx_mpc)
  n_ky = n_elements(ky_mpc)
  n_kz = n_elements(kz_mpc)
  
  uv_pix_area = (kx_mpc[1]-kx_mpc[0])*(ky_mpc[1]-ky_mpc[0])*kperp_lambda_conv^2.
  uv_area = uv_pix_area*n_kx*n_ky
  
  if keyword_set (no_kzero) then begin
    ;; leave out kz=0 -- full of foregrounds
    kz_mpc = kz_mpc[1:*]
    power_3d = temporary(power_3d[*, *, 1:*])
    weights_3d = temporary(weights_3d[*,*,1:*])
    noise_expval_3d = temporary(noise_expval_3d[*,*,1:*])
    if nfiles eq 2 then noise_3d = temporary(noise_3d[*,*,1:*])
    n_kz = n_elements(kz_mpc)
  endif
  
  power_tag = file_struct.power_tag
  
  fadd_2dbin = ''
  ;;if keyword_set(fill_holes) then fadd_2dbin = fadd_2dbin + '_nohole'
  if keyword_set(no_kzero) then fadd_2dbin = fadd_2dbin + '_nok0'
  if keyword_set(log_kpar) then fadd_2dbin = fadd_2dbin + '_logkpar'
  if keyword_set(log_kperp) then fadd_2dbin = fadd_2dbin + '_logkperp'
  
  git, repo_path = ps_repository_dir(), result=binning_git_hash
  if n_elements(git_hashes) gt 0 then git_hashes = create_struct(git_hashes, 'binning', binning_git_hash) $
  else git_hashes = {uvf:strarr(nfiles), uvf_wt:strarr(nfiles), beam:strarr(nfiles), kcube:'', ps:'', binning:binning_git_hash}
  
  
  print, 'Binning to 2D power spectrum'
  
  n_wt_cuts = n_elements(wt_cutoffs)
  
  for j=0, n_wt_cuts-1 do begin
  
    if wt_cutoffs[j] gt 0 then begin
      case wt_measures[j] of
        'ave': wt_meas_use = wt_meas_ave
        'min': wt_meas_use = wt_meas_min
      endcase
      
      wt_cutoff_use = wt_cutoffs[j]
    endif else undefine, wt_cutoff_use, wt_meas_use
    
    
    power_rebin = kspace_rebinning_2d(power_3D, kx_mpc, ky_mpc, kz_mpc, kperp_edges_mpc, kpar_edges_mpc, log_kpar = log_kpar, $
      log_kperp = log_kperp, kperp_bin = kperp_bin, kpar_bin = kpar_bin, $
      noise_expval = noise_expval_3d, binned_noise_expval = binned_noise_expval, weights = weights_3d, $
      binned_weights = binned_weights, fill_holes = fill_holes, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
    undefine, wt_cutoff_use, wt_meas_use
    if nfiles eq 2 then $
      noise_rebin = kspace_rebinning_2d(noise_3D, kx_mpc, ky_mpc, kz_mpc, kperp_edges_mpc, kpar_edges_mpc, log_kpar = log_kpar, $
      log_kperp = log_kperp, kperp_bin = kperp_bin, kpar_bin = kpar_bin, $
      noise_expval = noise_expval_3d, binned_noise_expval = binned_noise_expval, $
      weights = weights_3d, binned_weights = binned_weights, fill_holes = fill_holes, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
      
    power = power_rebin
    if nfiles eq 2 then noise = noise_rebin
    kperp_edges = kperp_edges_mpc
    kpar_edges = kpar_edges_mpc
    weights = binned_weights
    noise_expval = binned_noise_expval
    
    wh_good_kperp = where(total(weights, 2) gt 0, count)
    if count eq 0 then message, '2d weights appear to be entirely zero'
    kperp_plot_range = [min(kperp_edges[wh_good_kperp]), max(kperp_edges[wh_good_kperp+1])]
    
    if n_elements(freq_flags) ne 0 then begin
      save, file = savefile_2d[j], power, noise, weights, noise_expval, kperp_edges, kpar_edges, kperp_bin, kpar_bin, $
        kperp_lambda_conv, delay_params, hubble_param, freq_mask, vs_name, vs_mean, t_sys_meas, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endif else begin
      save, file = savefile_2d[j], power, noise, weights, noise_expval, kperp_edges, kpar_edges, kperp_bin, kpar_bin, $
        kperp_lambda_conv, delay_params, hubble_param, vs_name, vs_mean, t_sys_meas, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endelse
    
    if not keyword_set(quiet) then begin
      kpower_2d_plots, savefile_2d[j], kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        data_range = data_range
      kpower_2d_plots, savefile_2d[j], /plot_weights, kperp_plot_range = kperp_plot_range, kpar_plot_range = kpar_plot_range, $
        window_num = 2, title = 'Weights'
    endif
    
    ;; save just k0 line for plotting purposes
    if not keyword_set(no_kzero) then begin
      power = power[*,0]
      if n_elements(noise) gt 0 then noise = noise[*,0] ;else stop
      weights = weights[*,0]
      noise_expval = noise_expval[*,0]
      
      k_edges = kperp_edges
      k_bin = kperp_bin
      
      if n_elements(freq_flags) ne 0 then begin
        save, file = savefile_k0[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, freq_mask, $
          window_int, wt_ave_power, ave_power, ave_weights, uv_pix_area, uv_area, git_hashes
      endif else begin
        save, file = savefile_k0[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, $
          window_int, wt_ave_power, ave_power, ave_weights, uv_pix_area, uv_area, git_hashes
      endelse
    endif
  endfor
  
  ;; now do slices
  y_tot = total(total(abs(power_3d),3),1)
  wh_y_n0 = where(y_tot gt 0, count_y_n0)
  min_dist_y_n0 = min(wh_y_n0, min_loc)
  y_slice_ind = wh_y_n0[min_loc]
  
  yslice_savefile = file_struct.savefile_froot + file_struct.savefilebase + power_tag + '_xz_plane.idlsave'
  yslice_power = kpower_slice(power_3d, kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param, noise_3d = noise_3d, $
    noise_expval_3d = noise_expval_3d, weights_3d = weights_3d, slice_axis = 1, slice_inds = y_slice_ind, $
    slice_savefile = yslice_savefile)
    
    
  x_tot = total(total(abs(power_3d),3),2)
  wh_x_n0 = where(x_tot gt 0, count_x_n0)
  min_dist_x_n0 = min(abs(n_kx/2-wh_x_n0), min_loc)
  x_slice_ind = wh_x_n0[min_loc]
  
  xslice_savefile = file_struct.savefile_froot + file_struct.savefilebase + power_tag + '_yz_plane.idlsave'
  xslice_power = kpower_slice(power_3d, kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param, noise_3d = noise_3d, $
    noise_expval_3d = noise_expval_3d, weights_3d = weights_3d, slice_axis = 0, slice_inds = x_slice_ind, $
    slice_savefile = xslice_savefile)
    
  z_tot = total(total(abs(power_3d),3),1)
  wh_z_n0 = where(z_tot gt 0, count_z_n0)
  min_dist_z_n0 = min(wh_z_n0, min_loc)
  z_slice_ind = wh_y_n0[min_loc]
  
  zslice_savefile = file_struct.savefile_froot + file_struct.savefilebase + power_tag + '_xy_plane.idlsave'
  zslice_power = kpower_slice(power_3d, kx_mpc, ky_mpc, kz_mpc, kperp_lambda_conv, delay_params, hubble_param, noise_3d = noise_3d, $
    noise_expval_3d = noise_expval_3d, weights_3d = weights_3d, slice_axis = 2, slice_inds = z_slice_ind, $
    slice_savefile = zslice_savefile)
    
    
  print, 'Binning to 1D power spectrum'
  
  
  n_wt_cuts = n_elements(wt_cutoffs)
  
  if keyword_set(kperp_range_lambda_1dave) then kperp_range_use = kperp_range_lambda_1dave / kperp_lambda_conv
  if keyword_set(kperp_range_1dave) then kperp_range_use = kperp_range_1dave
  if keyword_set(kpar_range_1dave) then kpar_range_use = kpar_range_1dave
  
  if n_elements(savefile_1d) ne (n_elements(wedge_amp)+1)*(n_wt_cuts) then $
    message, 'number of elements in savefile_1d is wrong'
    
  for i=0, n_elements(wedge_amp) do begin
    for j=0, n_wt_cuts-1 do begin
      if i gt 0 then begin
        wedge_amp_use = wedge_amp[i-1]
        if n_elements(coarse_harm0) gt 0 then begin
          coarse_harm0_use = coarse_harm0
          coarse_width_use = coarse_width
        endif
      endif
      
      if wt_cutoffs[j] gt 0 then begin
        case wt_measures[j] of
          'ave': wt_meas_use = wt_meas_ave
          'min': wt_meas_use = wt_meas_min
        endcase
        
        wt_cutoff_use = wt_cutoffs[j]
      endif else undefine, wt_cutoff_use, wt_meas_use
      
      power_1d = kspace_rebinning_1d(power_3d, kx_mpc, ky_mpc, kz_mpc, k_edges_mpc, k_bin = k1d_bin, log_k = log_k1d, $
        noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_1d, weights = weights_3d, $
        binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, $
        wedge_amp = wedge_amp_use, coarse_harm0 = coarse_harm0_use, coarse_width = coarse_width_use, $
        kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
        
      if nfiles eq 2 then $
        noise_1d = kspace_rebinning_1d(noise_3d, kx_mpc, ky_mpc, kz_mpc, k_edges_mpc, k_bin = k1d_bin, log_k = log_k1d, $
        noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_1d, weights = weights_3d, $
        binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, $
        wedge_amp = wedge_amp_use, coarse_harm0 = coarse_harm0_use, coarse_width = coarse_width_use, $
        kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
        
      power = power_1d
      if nfiles eq 2 then noise = noise_1d
      weights = weights_1d
      k_edges = k_edges_mpc
      k_bin = k1d_bin
      noise_expval = noise_expval_1d
      kperp_range = kperp_range_use
      kperp_range_lambda = kperp_range_use * kperp_lambda_conv
      kpar_range = kpar_range_use
      
      if n_elements(freq_flags) ne 0 then begin
        save, file = savefile_1d[j,i], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, freq_mask, $
          kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
          wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
      endif else begin
        save, file = savefile_1d[j,i], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, $
          kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
          wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
      endelse
      
      textfile = strmid(savefile_1d[j,i], 0, stregex(savefile_1d[j,i], '.idlsave')) + '.txt'
      
      nrows = n_elements(k_edges)
      if nfiles eq 2 then ncol = 5 else ncol = 4
      data = fltarr(ncol, nrows)
      
      sigma_vals = sqrt(1./weights)
      wh_wt0 = where(weights eq 0, count_wh_wt0)
      if count_wh_wt0 gt 0 then sigma_vals[wh_wt0]= !values.f_infinity
      
      if not keyword_set(hinv) then begin
        data[0, *] = k_edges
        data[1, *] = [0, power]
        data[2, *] = [0, sigma_vals]
        data[3, *] = [0, noise_expval]
        header = ['k bin max (Mpc^-1)', 'power (mK^2 Mpc^3)', 'sigma (mK^2 Mpc^3)', 'expected noise (mK^2 Mpc^3)']
        if nfiles eq 2 then begin
          data[4,*] = [0, noise]
          header = [header, 'observed noise (mK^2 Mpc^3)']
        endif
      endif else begin
        data[0, *] = k_edges / hubble_param
        data[1, *] = [0, power] * (hubble_param)^3d
        data[2, *] = [0, sigma_vals] * (hubble_param)^3d
        data[3, *] = [0, noise_expval] * (hubble_param)^3d
        header = ['k bin max (h Mpc^-1)', 'power (mK^2 h^-3 Mpc^3)', 'sigma (mK^2 h^-3 Mpc^3)', 'expected noise (mK^2 h^-3 Mpc^3)']
        if nfiles eq 2 then begin
          data[4,*] = [0, noise] * (hubble_param)^3d
          header = [header, 'observed noise (mK^2 h^-3 Mpc^3)']
        endif
      endelse
      
      data_use = Strarr(ncol,nrows+1)
      data_use[*,0]=header
      data_use[*,1:*]=(data)
      
      delimiter=String(9B)
      format_code=String(format='("(",A,"(A,",A,A,A,"))")',Strn(ncol),'"',delimiter,'"')
      
      openw,unit,textfile,/Get_LUN
      printf,unit,format=format_code,data_use
      free_lun,unit
    endfor
  endfor
  
  if not keyword_set(quiet) then begin
    kpower_1d_plots, savefile_1d, window_num = 5
  endif
  
  ;; bin just in kpar for diagnostic plot
  
  for j=0, n_wt_cuts-1 do begin
    if wt_cutoffs[j] gt 0 then begin
      case wt_measures[j] of
        'ave': wt_meas_use = wt_meas_ave
        'min': wt_meas_use = wt_meas_min
      endcase
      
      wt_cutoff_use = wt_cutoffs[j]
    endif else undefine, wt_cutoff_use, wt_meas_use
    
    power_kpar = kspace_rebinning_1d(power_3d, kx_mpc, ky_mpc, kz_mpc, kpar_edges_mpc, k_bin = kpar_bin, log_k = log_kpar, $
      noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_kpar, weights = weights_3d, $
      binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, /kpar_power, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
    if nfiles eq 2 then $
      noise_kpar = kspace_rebinning_1d(noise_3d, kx_mpc, ky_mpc, kz_mpc, kpar_edges_mpc, k_bin = kpar_bin, log_k = log_kpar, $
      noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_kpar, weights = weights_3d, $
      binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, /kpar_power, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
    power = power_kpar
    if nfiles eq 2 then noise = noise_kpar
    weights = weights_1d
    k_edges = kpar_edges_mpc
    k_bin = kpar_bin
    noise_expval = noise_expval_kpar
    kperp_range = kperp_range_use
    kperp_range_lambda = kperp_range_use * kperp_lambda_conv
    kpar_range = kpar_range_use
    
    if n_elements(freq_flags) ne 0 then begin
      save, file = savefile_kpar_power[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, freq_mask, $
        kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endif else begin
      save, file = savefile_kpar_power[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, $
        kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endelse
  endfor
  
  ;; bin just in kperp for diagnostic plot
  
  for j=0, n_wt_cuts-1 do begin
    if wt_cutoffs[j] gt 0 then begin
      case wt_measures[j] of
        'ave': wt_meas_use = wt_meas_ave
        'min': wt_meas_use = wt_meas_min
      endcase
      
      wt_cutoff_use = wt_cutoffs[j]
    endif else undefine, wt_cutoff_use, wt_meas_use
    power_kperp = kspace_rebinning_1d(power_3d, kx_mpc, ky_mpc, kz_mpc, kperp_edges_mpc, k_bin = kperp_bin, log_k = log_kperp, $
      noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_kperp, weights = weights_3d, $
      binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, /kperp_power, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
    if nfiles eq 2 then $
      noise_kperp = kspace_rebinning_1d(noise_3d, kx_mpc, ky_mpc, kz_mpc, kperp_edges_mpc, k_bin = kperp_bin, log_k = log_kperp, $
      noise_expval = noise_expval_3d, binned_noise_expval = noise_expval_kperp, weights = weights_3d, $
      binned_weights = weights_1d, kperp_range = kperp_range_use, kpar_range = kpar_range_use, /kperp_power, $
      kperp_density_measure = wt_meas_use, kperp_density_cutoff = wt_cutoff_use)
      
    power = power_kperp
    if nfiles eq 2 then noise = noise_kperp
    weights = weights_1d
    k_edges = kperp_edges_mpc
    k_bin = kperp_bin
    noise_expval = noise_expval_kperp
    kperp_range = kperp_range_use
    kperp_range_lambda = kperp_range_use * kperp_lambda_conv
    kpar_range = kpar_range_use
    
    if n_elements(freq_flags) ne 0 then begin
      save, file = savefile_kperp_power[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, freq_mask, $
        kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endif else begin
      save, file = savefile_kperp_power[j], power, noise, weights, noise_expval, k_edges, k_bin, hubble_param, $
        kperp_range, kperp_range_lambda, kpar_range, window_int, git_hashes, $
        wt_ave_power, ave_power, ave_weights, wt_ave_power_freq, ave_power_freq, wt_ave_power_uvf, ave_power_uvf, uv_pix_area, uv_area
    endelse
  endfor
  
end
