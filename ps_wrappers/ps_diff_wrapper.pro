pro ps_diff_wrapper, folder_names_in, obs_names_in, $
    ps_foldernames = ps_foldernames, version_test = version_test, $
    cube_types = cube_types, pols = pols,  refresh_diff = refresh_diff, $
    spec_window_types = spec_window_types, delta_uv_lambda = delta_uv_lambda, $
    max_uv_lambda = max_uv_lambda, full_image = full_image, $
    image_clip = image_clip, ave_removal = ave_removal, $
    freq_dft = freq_dft, dft_z_use = dft_z_use, std_power = std_power, $
    all_type_pol = all_type_pol, freq_ch_range = freq_ch_range, $
    plot_slices = plot_slices, slice_type = slice_type, $
    png = png, eps = eps, pdf = pdf, data_range = data_range, data_min_abs = data_min_abs, $
    kperp_linear_axis = kperp_linear_axis, kpar_linear_axis = kpar_linear_axis, sim = sim, $
    plot_1d = plot_1d, axis_type_1d=axis_type_1d, wt_cutoffs = wt_cutoffs, $
    wt_measures = wt_measures, window_num = window_num, $
    color_type = color_type, invert_colorbar = invert_colorbar, $
    diff_save_path = diff_save_path, exact_obsnames = exact_obsnames, $
    uvf_input = uvf_input, plot_path = diff_plot_path, $
    wedge_angles = wedge_angles, wedge_names = wedge_names, $
    coarse_harm_width = coarse_harm_width, $
    no_kzero = no_kzero, log_kpar = log_kpar, log_kperp = log_kperp, $
    kpar_bin = kpar_bin, kperp_bin = kperp_bin, $
    log_k1d = log_k1d, k1d_bin = k1d_bin, $
    kpar_range_1dave = kpar_range_1dave, kperp_range_1dave = kperp_range_1dave, $
    kperp_range_lambda_1dave = kperp_range_lambda_1dave, kx_range_1dave = kx_range_1dave, $
    kx_range_lambda_1dave = kx_range_lambda_1dave, ky_range_1dave = ky_range_1dave, $
    ky_range_lambda_1dave = ky_range_lambda_1dave, $
    kperp_range_lambda_kparpower = kperp_range_lambda_kparpower, $
    kpar_range_kperppower = kpar_range_kperppower, $
    kperp_plot_range = kperp_plot_range, kperp_lambda_plot_range = kperp_lambda_plot_range

  if n_elements(folder_names_in) gt 2 then message, 'only 1 or 2 folder_names allowed'
  if n_elements(folder_names_in) eq 0 then message, 'at least 1 folder name must be specified'
  if n_elements(obs_names_in) gt 2 then message, 'only 1 or 2 obs_names_in allowed'

  folder_names = get_folder(folder_names_in, loc_name = loc_name,  rts = rts, $
    dirty_folder = dirty_folder)

  if keyword_set(version_test) and n_elements(ps_foldername) eq 0 $
      and n_elements(folder_names_in) eq 1 and n_elements(obs_names_in) lt 2 then begin
    git_info = git_info(ps_repository_dir())
    ps_foldernames = ['ps_master', 'ps_' + git_info.branch]
  endif

  obs_info = ps_filenames(folder_names, obs_names_in, dirty_folder = dirty_folder, $
    exact_obsnames = exact_obsnames, rts = rts, sim = sim,  uvf_input = uvf_input, $
    casa = casa, data_subdirs = data_subdirs, ps_foldernames = ps_foldernames, $
    save_paths = save_paths, plot_paths = plot_paths, refresh_info = refresh_info, $
    no_wtvar_rts = no_wtvar_rts)

  binning_2d_options = create_binning_2d_options(no_kzero = no_kzero, $
    log_kpar = log_kpar, log_kperp = log_kperp, kpar_bin = kpar_bin, kperp_bin = kperp_bin)

  binning_1d_options = create_binning_1d_options(wedge_angles = wedge_angles, $
    wedge_names = wedge_names, $
    coarse_harm_width = coarse_harm_width, log_k = log_k1d, k_bin = k1d_bin, $
    kpar_range_1dave = kpar_range_1dave, kperp_range_1dave = kperp_range_1dave, $
    kperp_range_lambda_1dave = kperp_range_lambda_1dave, kx_range_1dave = kx_range_1dave, $
    kx_range_lambda_1dave = kx_range_lambda_1dave, ky_range_1dave = ky_range_1dave, $
    ky_range_lambda_1dave = ky_range_lambda_1dave, $
    kperp_range_lambda_kparpower = kperp_range_lambda_kparpower, $
    kpar_range_kperppower = kpar_range_kperppower)

  if n_elements(diff_plot_path) eq 0 then begin
    if n_elements(diff_save_path) gt 0 then begin
      diff_plot_path = diff_save_path + path_sep() + 'plots' + path_sep()
    endif
  endif

  wh_noinfo = where(obs_info.info_files eq '', count_noinfo)
  if count_noinfo gt 0 then message, 'Info files are not all present'

  if n_elements(delta_uv_lambda) gt 1 then message, 'only 1 delta_uv_lambda allowed'

  if n_elements(max_uv_lambda) lt 2 and n_elements(full_image) lt 2 $
     and n_elements(image_clip) lt 2 then begin

    uvf_options0 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = max_uv_lambda, full_image = full_image, image_clip = image_clip)

  endif else begin
    case n_elements(max_uv_lambda) of
      0:
      1: begin
        mul0 = max_uv_lambda
        mul1 = max_uv_lambda
      end
      2: begin
        mul0 = max_uv_lambda[0]
        mul1 = max_uv_lambda[1]
      end
      else: message, 'only 1 or 2 max_uv_lambda values allowed'
    endcase

    case n_elements(full_image) of
      0:
      1: begin
        fi0 = full_image
        fi1 = full_image
      end
      2: begin
        fi0 = full_image[0]
        fi1 = full_image[1]
      end
    endcase

    case n_elements(image_clip) of
        0:
        1: begin
          ic0 = image_clip
          ic1 = image_clip
        end
        2: begin
          ic0 = image_clip[0]
          ic1 = image_clip[1]
        end
      else: message, 'only 1 or 2 image_clip values allowed'
    endcase

    uvf_options0 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = mul0, full_image = fi0, image_clip = ic0)
    uvf_options1 = create_uvf_options(delta_uv_lambda = delta_uv_lambda, $
      max_uv_lambda = mul1, full_image = fi1, image_clip = ic1)
  endelse

  if n_elements(ave_removal) lt 2 and n_elements(wt_cutoffs) lt 2 and $
    n_elements(wt_measures) lt 2 and n_elements(spec_window_types) lt 2 and $
    n_elements(freq_dft) lt 2 and n_elements(dft_z_use) lt 2 and $
    n_elements(std_power) lt 2 then begin

    ps_options = create_ps_options(ave_removal = ave_removal, $
    wt_cutoffs = wt_cutoffs, wt_measures = wt_measures, $
    spec_window_type = spec_window_types, $
    freq_dft = freq_dft, dft_z_use = dft_z_use, $
    std_power = std_power)

  endif else begin
    case n_elements(ave_removal) of
      0:
      1: begin
        ar0 = ave_removal
        ar1 = ave_removal
      end
      2: begin
        ar0 = ave_removal[0]
        ar1 = ave_removal[1]
      end
      else: message, 'only 1 or 2 ave_removal values allowed'
    endcase

    case n_elements(wt_cutoffs) of
      0:
      1: begin
        wtc0 = wt_cutoffs
        wtc1 = wt_cutoffs
      end
      2: begin
        wtc0 = wt_cutoffs[0]
        wtc1 = wt_cutoffs[1]
      end
      else: message, 'only 1 or 2 wt_cutoffs allowed'
    endcase

    case n_elements(wt_measures) of
      0:
      1: begin
        wtm0 = wt_measures
        wtm1 = wt_measures
      end
      2: begin
        wtm0 = wt_measures[0]
        wtm1 = wt_measures[1]
      end
      else: message, 'only 1 or 2 wt_measures allowed'
    endcase

    case n_elements(spec_window_types) of
      0:
      1: begin
        spw0 = spec_window_types
        spw1 = spec_window_types
      end
      2: begin
        spw0 = spec_window_types[0]
        spw1 = spec_window_types[1]
      end
      else: message, 'only 1 or 2 spec_window_types allowed'
    endcase

    case n_elements(freq_dft) of
      0:
      1: begin
        dft0 = freq_dft
        dft1 = freq_dft
      end
      2: begin
        dft0 = freq_dft[0]
        dft1 = freq_dft[1]
      end
      else: message, 'only 1 or 2 freq_dft values allowed'
    endcase

    case n_elements(dft_z_use) of
      0:
      1: begin
        dftz0 = dft_z_use
        dftz1 = dft_z_use
      end
      2: begin
        dftz0 = dft_z_use[0]
        dftz1 = dft_z_use[1]
      end
      else: message, 'only 1 or 2 dft_z_use values allowed'
    endcase

    case n_elements(std_power) of
      0:
      1: begin
        sp0 = std_power
        sp1 = std_power
      end
      2: begin
        sp0 = std_power[0]
        sp1 = std_power[1]
      end
      else: message, 'only 1 or 2 std_power values allowed'
    endcase

    ps_options0 = create_ps_options(ave_removal = ar0, wt_cutoffs = wtc0, $
      wt_measures = wtm0, spec_window_type = spw0, freq_dft = dft0, $
      dft_z_use = dftz0, std_power = sp0)

    ps_options1 = create_ps_options(ave_removal = ar1, wt_cutoffs = wtc1, $
      wt_measures = wtm1, spec_window_type = spw1, freq_dft = dft1, $
      dft_z_use = dftz1, std_power = sp1)

    ps_options = [ps_options0, ps_options1]
  endelse

  plot_options = create_plot_options(plot_path = diff_plot_path, $
    png = png, eps = eps, pdf = pdf)

  plot_2d_options = create_plot_2d_options(kperp_linear_axis = kperp_linear_axis, $
    kpar_linear_axis = kpar_linear_axis, $
    kperp_plot_range = kperp_plot_range, kperp_lambda_plot_range = kperp_lambda_plot_range, $
    data_range = data_range, color_type = color_type)

  ps_difference_plots, folder_names, obs_info, ps_foldernames = ps_foldernames, $
    cube_types, pols, uvf_options0 = uvf_options0, uvf_options1 = uvf_options1, $
    ps_options = ps_options, $
    plot_options = plot_options, plot_2d_options = plot_2d_options, $
    binning_2d_options = binning_2d_options, binning_1d_options = binning_1d_options, $
    all_type_pol = all_type_pol, refresh_diff = refresh_diff, freq_ch_range = freq_ch_range, $
    plot_slices = plot_slices, slice_type = slice_type, $
    save_path = diff_save_path, savefilebase = savefilebase, $
    plot_1d = plot_1d, axis_type_1d = axis_type_1d, $
    invert_colorbar = invert_colorbar, data_min_abs = data_min_abs, $
    quiet = quiet, window_num = window_num

end
