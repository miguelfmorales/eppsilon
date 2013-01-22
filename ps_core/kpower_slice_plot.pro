

pro kpower_slice_plot, slice_savefile, multi_pos = multi_pos, multi_aspect = multi_aspect, $
                       plot_xrange = plot_xrange, plot_yrange = plot_yrange, data_range = data_range, $
                       pub = pub, plotfile = plotfile, color_profile = color_profile, log_cut_val = log_cut_val, $
                       window_num = window_num, title = title, grey_scale = grey_scale, plot_wedge_line = plot_wedge_line, $
                       wedge_amp = wedge_amp, linear_axes = linear_axes, baseline_axis = baseline_axis

  if n_elements(window_num) eq 0 then window_num = 1

  if n_elements(multi_pos) gt 0 then begin
     if n_elements(multi_pos) ne 4 then message, 'multi_pos must be a 4 element plot position vector'
     if max(multi_pos) gt 1 or min(multi_pos) lt 0 then message, 'multi_pos must be in normalized coordinates (between 0 & 1)'
     if multi_pos[2] le multi_pos[0] or multi_pos[3] le multi_pos[1] then $
        message, 'In multi_pos, x1 must be greater than x0 and y1 must be greater than y0 '

     if n_elements(multi_aspect) eq 0 then begin
        print, 'No aspect ratio for multi_pos supplied. Assuming aspect = 1'
        multi_aspect = 1
     endif else if n_elements(multi_aspect) gt 1 then message, 'too many elements in multi_aspect'
  endif

  color_profile_enum = ['log_cut', 'sym_log', 'abs']
  if n_elements(color_profile) eq 0 then color_profile = 'log_cut'

  wh_prof = where(color_profile_enum eq color_profile, count)
  if count eq 0 then message, 'Color profile must be one of: ' + strjoin(color_profile_enum, ', ')


  restore, slice_savefile

  if n_elements(slice_inds) gt 1 then power_slice = total(power, slice_axis+1) / n_elements(slice_inds) $
  else power_slice = reform(power)

  xdelta = xarr[1] - xarr[0]
  ydelta = yarr[1] - yarr[0]

  xarr_edges = [xarr - xdelta/2, max(xarr) + xdelta/2]
  yarr_edges = [yarr - ydelta/2, max(yarr) + ydelta/2]

  if n_elements(plot_xrange) eq 0 then begin
     temp = where(total(power_slice,2) gt 0)

     if keyword_set(linear_axes) then plot_xrange =  minmax(xarr_edges[[temp, max(temp)+1]]) $
     else plot_xrange = [0, max(xarr_edges[[temp, max(temp)+1]])]
  endif

  if n_elements(plot_yrange) eq 0 then begin
      temp = where(total(power_slice,1) gt 0)
      plot_yrange = minmax(yarr_edges[[temp, max(temp)+1]])
  endif
  
  wh_x_inrange = where(xarr ge plot_xrange[0] and xarr + xdelta le plot_xrange[1], n_x_plot)
  wh_y_inrange = where(yarr ge plot_yrange[0] and yarr + ydelta le plot_yrange[1], n_y_plot)


  if n_elements(plotfile) eq 0 then $
      plotfile = base_path() + 'power_spectrum/plots/' + plane_name + ' plane.eps' $
   else if strcmp(strmid(plotfile, strlen(plotfile)-4), '.eps', /fold_case) eq 0 then plotfile = plotfile + '.eps'
  
  
  if n_x_plot eq 0 or n_y_plot eq 0 then message, 'No data in plot k range'

  if n_x_plot ne n_elements(xarr) then begin
     power_slice = power_slice[wh_x_inrange, *]
     xarr = xarr[wh_x_inrange]
  endif
  if n_y_plot ne n_elements(yarr) then begin
     power_slice = power_slice[*, wh_y_inrange]
     yarr = yarr[wh_y_inrange]
  endif
  power_3d=0
  xarr_edges = [xarr - xdelta/2, max(xarr) + xdelta/2]
  yarr_edges = [yarr - ydelta/2, max(yarr) + ydelta/2]

  tvlct, r, g, b, /get

  if keyword_set(grey_scale) then begin
     cgloadct, 0, /reverse
     color_range = [0, 255]
     background_color = 'white'
     annotate_color = 'black'
  endif else begin
     cgloadct, 25, /brewer, /reverse
     color_range = [0, 255]
     background_color = 'white'
     annotate_color = 'black'
  endelse
  n_colors = color_range[1] - color_range[0]
  
  if max(abs(power_slice)) eq 0 then all_zero = 1

  if n_elements(data_range) eq 0 then if not keyword_set(all_zero) then data_range = minmax(power_slice) else data_range = [1e-1, 1e0]
  wh = where(power_slice gt 0d, count)
  if count gt 0 then min_pos = min(power_slice[wh]) else if keyword_set(all_zero) then min_pos = data_range[0]

  if keyword_set(linear_axes) then begin
     power_plot = congrid(power_slice, n_x_plot*10, n_y_plot * 10)
     xlog = 0
     ylog = 0

  endif else begin
     ;; make a new image array to allow log axes
     wh_x0 = where(xarr eq 0, count_x0, complement = wh_x_good)
     if count_x0 gt 1 then stop
     if count_x0 eq 1 then log_x = alog10(xarr[wh_x_good]) else log_x = alog10(xarr)
     log_x_diffs = log_x - shift(log_x, 1)
     log_x_diffs = log_x_diffs[1:*]
     if count_x0 eq 1 then begin
        log_x = alog10(xarr)
        log_x[wh_x0] = log_x[wh_x0+1] - max(log_x_diffs)
        log_x_diffs = log_x - shift(log_x, 1)
        log_x_diffs = log_x_diffs[1:*]
     endif
     log_x_edges = [log_x - [log_x_diffs, min(log_x_diffs)]/2d, max(log_x) + min(log_x_diffs)]
     image_x_delta = min(log_x_diffs)/1d
     
     wh_y0 = where(yarr eq 0, count_y0, complement = wh_y_good)
     if count_y0 gt 1 then stop
     if count_y0 eq 1 then log_y = alog10(yarr[wh_y_good]) else log_y = alog10(yarr)
     log_y_diffs = log_y - shift(log_y, 1)
     log_y_diffs = log_y_diffs[1:*]
     if count_y0 eq 1 then begin
        log_y = alog10(yarr)
        log_y[wh_y0] = log_y[wh_y0+1] - max(log_y_diffs)
        log_y_diffs = log_y - shift(log_y, 1)
        log_y_diffs = log_y_diffs[1:*]
     endif
     log_y_edges = [log_y - [log_y_diffs, min(log_y_diffs)]/2d, max(log_y) + min(log_y_diffs)]
     image_y_delta = min(log_y_diffs)/1d
     
     ;; now get width for each input bin in image array
     image_delta = min(image_x_delta, image_y_delta)
     xbin_widths = round([log_x_diffs, min(log_x_diffs)] / image_delta) 
     nx_image = total(xbin_widths)
     ybin_widths = round([log_y_diffs, min(log_y_diffs)] / image_delta) 
     ny_image = total(ybin_widths)
     
     hx = histogram(total(xbin_widths,/cumulative)-1,binsize=1, min=0, reverse_indices=rix)
     hx=0
     xinds = rebin(rix[0:nx_image-1]-rix[0], nx_image, ny_image)
     
     hy = histogram(total(ybin_widths,/cumulative)-1,binsize=1, min=0, reverse_indices=riy)
     hy=0
     yinds = rebin(reform(riy[0:ny_image-1]-riy[0], 1, ny_image), nx_image, ny_image)

     power_plot = power_slice[xinds, yinds]
     xlog = 1
     ylog = 1

  endelse

  case color_profile of
     'log_cut': begin

        if data_range[1] lt 0 then message, 'log_cut color profile will not work for entirely negative arrays.'
        
        if n_elements(log_cut_val) eq 0 then begin 
           if data_range[0] gt 0 then log_cut_val = alog10(data_range[0]) else $
              log_cut_val = alog10(min_pos)
        endif

        log_data_range = [log_cut_val, alog10(data_range[1])]

        power_log = alog10(power_plot)
        wh_under = where(power_plot lt 10^double(log_cut_val), count)
        if count ne 0 then power_log[wh_under] = log_data_range[0]
        wh_over = where(power_log gt log_data_range[1], count)
        if count ne 0 then power_log[wh_over] = log_data_range[1]
     end
     'sym_log': begin

        ;; want log-like behavior on each side of 0: log(pos. vals +1) & log((-1)*neg. vals+1)
        neg_inds = where(power_plot lt 0, n_neg, complement = pos_inds, ncomplement = n_pos)
          
        power_log = alog10(power_plot+1)
        if n_neg gt 0 then power_log[neg_inds] = (-1) * alog10((-1)*power_plot[neg_inds] + 1)
        
        log_data_range = alog10(data_range + 1)
        if data_range[0] lt 0 then begin
           temp = alog10((-1)*data_range[0]+1)
           if temp gt log_data_range[1] then log_data_range = [(-1)*temp, temp] $
           else log_data_range[0] = (-1)*log_data_range[1]
        endif
     end
     'abs': begin

        abs_power_plot = abs(power_plot)
        log_data_range = dblarr(2)
        if data_range[0] lt 0 then log_data_range[0] = alog10(min(abs_power_plot[where(abs_power_plot gt 0)])) $
        else log_data_range[0] = alog10(data_range[0])
        log_data_range[1] = alog10(max(abs(data_range)))

        power_log = alog10(abs_power_plot)
        wh_zero = where(power_plot eq 0, count)
        if count ne 0 then power_log[wh_zero] = log_data_range[0]

        abs_power_plot = 0

     end
  endcase
     
  power_log_norm = (power_log-log_data_range[0])*n_colors/(log_data_range[1]-log_data_range[0]) + color_range[0]
  if keyword_set(all_zero) then power_log_norm = power_log_norm * 0 + annotate_color

  ;; Work out plot & colorbar positions
  ;; in units of plot area (incl. margins)
  cb_size = 0.025
  margin1 = [0.15, 0.15]
  margin2 = [0.02, 0.1]
  cb_margin1 = 0.08
  cb_margin2 = 0.02
  if keyword_set(baseline_axis) then if (n_elements(multi_pos) gt 0 and keyword_set(pub)) then margin2[1] = 0.3 else margin2[1] = 0.15

  if keyword_set(baseline_axis) and slice_axis eq 2 then margin2[0] = 0.08

  plot_pos = [margin1[0], margin1[1], (1-cb_margin2-cb_size-cb_margin1-margin2[0]), (1-margin2[1])]
  cb_pos = [(1-cb_margin2-cb_size), margin1[1], (1-cb_margin2), (1-margin2[1])]

  plot_aspect = (plot_pos[3] - plot_pos[1]) / (plot_pos[2] - plot_pos[0])

  if keyword_set(linear_axes) then begin
     plot_xlength = max(xarr_edges) - min(xarr_edges)
     plot_ylength = (max(yarr_edges) - min(yarr_edges))*5d
  endif else begin
     plot_xlength = max(log_x_edges) - min(log_x_edges)
     plot_ylength = max(log_y_edges) - min(log_y_edges)
  endelse 

  data_aspect = (plot_ylength / plot_xlength)
  aspect_ratio =  data_aspect /plot_aspect
  
  if aspect_ratio gt 1 then begin
     y_factor = 1.
     x_factor = 1/aspect_ratio
  endif else begin

     y_factor = aspect_ratio
     x_factor = 1.
  endelse
  
  if n_elements(multi_pos) eq 4 then begin
     ;; work out positions scaled to the area allowed in multi_pos with proper aspect ratio
     multi_xlen = (multi_pos[2]-multi_pos[0])
     multi_ylen = (multi_pos[3]-multi_pos[1])
     multi_center = [multi_pos[0] + multi_xlen/2d, multi_pos[1] + multi_ylen/2d]
     
     new_aspect = aspect_ratio/multi_aspect
     if new_aspect gt 1 then begin
        y_factor = 1.
        x_factor = 1/new_aspect
     endif else begin          
        y_factor = new_aspect
        x_factor = 1.
     endelse
     
     new_xlen = multi_xlen*x_factor
     new_ylen = multi_ylen*y_factor
     new_multi = [multi_center[0] - new_xlen/2d, multi_center[1] - new_ylen*y_factor/2d, $
                  multi_center[0] + new_xlen/2d, multi_center[1] + new_ylen*y_factor/2d]
     
     new_pos = [new_xlen * plot_pos[0] + new_multi[0], new_ylen * plot_pos[1] + new_multi[1], $
                new_xlen * plot_pos[2] + new_multi[0], new_ylen * plot_pos[3] + new_multi[1]]
     
     new_cb_pos = [new_xlen * cb_pos[0] + new_multi[0], new_ylen * cb_pos[1] + new_multi[1], $
                   new_xlen * cb_pos[2] + new_multi[0], new_ylen * cb_pos[3] + new_multi[1]]
     
     plot_pos = new_pos
     cb_pos = new_cb_pos
     
     no_erase = 1
  endif else begin
     base_size = 600
     xsize = round(base_size * x_factor)
     ysize = round(base_size * y_factor)
     
     if not keyword_set(pub) then begin
        while ysize gt 1100 do begin
           base_size = base_size - 100
           xsize = round(base_size * x_factor)
           ysize = round(base_size * y_factor)
        endwhile
     endif

     no_erase = 0
  endelse

  if not keyword_set(no_title) then begin
     xloc_title = (plot_pos[2] - plot_pos[0])/2. + plot_pos[0]
     if n_elements(multi_pos) gt 0 then yloc_title = plot_pos[3] + 0.8* (multi_pos[3]-plot_pos[3]) $
     else yloc_title = plot_pos[3] + 0.6* (1-plot_pos[3])
  endif

  if n_elements(multi_pos) gt 0 then begin
     xloc_lambda = plot_pos[0] - 0.2* (plot_pos[0]-multi_pos[0])
     yloc_lambda = plot_pos[3] + 0.2* (multi_pos[3]-plot_pos[3])

     xloc2_lambda = plot_pos[2] + 0.2* (multi_pos[2]-plot_pos[2])
     yloc2_lambda = plot_pos[1] - 0.2* (plot_pos[1]-multi_pos[1])
  endif else begin
     xloc_lambda = plot_pos[0] - 0.1* (plot_pos[0]-0)
     yloc_lambda = plot_pos[3] + 0.1* (1-plot_pos[3])

     xloc2_lambda = plot_pos[2] + 0.1* (1-plot_pos[2])
     yloc2_lambda = plot_pos[1] - 0.1* (plot_pos[1]-0)
  endelse

  if keyword_set(pub) then begin
     charthick = 3
     thick = 3
     xthick = 3
     ythick = 3
     if n_elements(multi_pos) gt 0 then begin
        min_len = min([multi_xlen, multi_ylen])
        charsize = 5d * min_len
     endif else charsize = 2
     font = 1
     
     if n_elements(multi_pos) eq 0 then begin
        window, window_num, xsize = xsize, ysize = ysize
        pson, file = plotfile, /eps 
     endif
    
  endif else begin
     thick = 1
     charsize=1
     if n_elements(multi_pos) eq 0 then begin
        if windowavailable(window_num) then begin 
           wset, window_num
           if !d.x_size ne xsize or !d.y_size ne ysize then make_win = 1 else make_win = 0
        endif else make_win = 1
        
        if make_win eq 1 then window, window_num, xsize = xsize, ysize = ysize
     endif
  endelse


  if n_elements(title) ne 0 then plot_title = title + textoidl(' (mK^2 Mpc^3)', font = font) $
  else plot_title = plane_name + ' plane' + textoidl('(mK^2 Mpc^3)', font = font)

  if keyword_set(baseline_axis) then initial_title = '' else initial_title = plot_title

  plot_xtitle = 'k' + plot_xname + ' (Mpc!U-1!N)'
  plot_ytitle = 'k' + plot_yname + ' (Mpc!U-1!N)'

  if keyword_set(linear_axes) then begin
     plot_xarr = xarr_edges
     plot_yarr = yarr_edges
  endif else begin
     plot_xarr = 10^(log_x_edges)
     plot_yarr = 10^(log_y_edges)
  endelse

  cgplot, plot_xarr, plot_yarr, /nodata, xlog=xlog, ylog=ylog, xstyle=5, ystyle=5, title = initial_title, position = plot_pos, $
          xrange = minmax(plot_xarr), yrange = minmax(plot_yarr), thick = thick, charthick = charthick, xthick = xthick, $
          ythick = ythick, charsize = charsize, font = font, noerase = no_erase, background = background_color, color = annotate_color
  
  cgimage, power_log_norm, /nointerp,/overplot,/noerase
  if keyword_set(plot_wedge_line) then $
     cgplot, /overplot, plot_xarr, abs(plot_xarr * wedge_amp), color = annotate_color, thick = thick+1, psym=-0, linestyle = 2
  cgaxis, xaxis=0, xtick_get = xticks, xtitle = plot_xtitle, xrange = minmax(plot_xarr), $
          charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, font = font, $
          xtickformat = 'exponent', xstyle = 1, color = annotate_color
  cgaxis, yaxis=0, ytick_get = yticks, ytitle = plot_ytitle, yrange = minmax(plot_yarr), $
          charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, font = font, $
          ytickformat = 'exponent', ystyle = 1, color = annotate_color

  if keyword_set(baseline_axis) then begin
     cgaxis, xaxis=1, xrange = minmax(plot_xarr* kperp_lambda_conv), xtickformat = 'exponent', xthick = xthick, $
             charthick = charthick, ythick = ythick, charsize = charsize, font = font, xstyle = 1, color = annotate_color

     if not keyword_set(no_title) then cgtext, xloc_title, yloc_title, plot_title, /normal, alignment=0.5, charsize=1.2 * charsize, $
                                               color = annotate_color, font = font
     cgtext, xloc_lambda, yloc_lambda, textoidl('(\lambda)', font = font), /normal, alignment=0.5, charsize=charsize, $
             color = annotate_color, font = font
  endif else $
     cgaxis, xaxis=1, xrange = minmax(plot_xarr), xtickv = xticks, xtickname = replicate(' ', n_elements(xticks)), $
             charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, font = font, xstyle = 1, $
             color = annotate_color

  if keyword_set(baseline_axis) and slice_axis eq 2 then begin
     cgaxis, yaxis=1, yrange = minmax(plot_yarr * kperp_lambda_conv), ytickformat = 'exponent', xthick = xthick, $
             charthick = charthick, ythick = ythick, charsize = charsize, font = font, ystyle = 1, color = annotate_color

      cgtext, xloc2_lambda, yloc2_lambda, textoidl('(\lambda)', font = font), /normal, alignment=0.5, charsize=charsize, $
             color = annotate_color, font = font
  endif else $
     cgaxis, yaxis=1, yrange = minmax(plot_yarr), ytickv = yticks, ytickname = replicate(' ', n_elements(yticks)), $
             charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, font = font, ystyle = 1, $
             color = annotate_color

  temp = [ceil(log_data_range[0]), floor(log_data_range[1])]
  if temp[1] lt temp[0] then temp = reverse(temp)
  tick_vals = 10^(dindgen(temp[1]-temp[0] + 1) + temp[0])
  nloop = 0
  while(n_elements(tick_vals) gt 8) do begin
     nloop = nloop + 1
     factor = double(nloop+1)
     if color_profile eq 'sym_log' then begin
        pos_exp_vals = dindgen(ceil((temp[1]-temp[0] + 1)/(2d*factor)) + 1)*factor
        if max(pos_exp_vals) gt temp[1] then pos_exp_vals = pos_exp_vals[0:n_elements(pos_exp_vals)-2]

        exp_vals = [(-1)*reverse(pos_exp_vals[1:*]), pos_exp_vals]
     endif else begin 
        exp_vals = (dindgen(ceil((temp[1]-temp[0] + 1)/factor) + 1)*factor + temp[0])
        if max(exp_vals) gt temp[1] then exp_vals = exp_vals[0:n_elements(exp_vals)-2]
     endelse
     tick_vals = 10^exp_vals
  endwhile

  if color_profile eq 'sym_log' then begin
     names = strarr(n_elements(tick_vals))

     wh_neg = where(tick_vals lt 0, count_neg)
     wh_pos = where(tick_vals gt 0, count_pos)
     wh_zero = where(tick_vals eq 0, count_zero)
     if count_pos gt 0 then names[wh_pos] = '10!U' + strtrim(string(round(alog10(tick_vals[wh_pos])-1)), 2) + '!N'
     if count_neg gt 0 then names[wh_neg] = '-10!U' + strtrim(string(round(alog10(tick_vals[wh_neg])+1)), 2) + '!N'
     if count_zero gt 0 then names[wh_zero] = '0'
  endif else begin

     ;; if log_data_range[0] lt min_pos then begin
     ;;    wh = where(tick_vals lt min_pos, count, complement = wh_keep, ncomplement = count_keep) 
     ;;    if count_keep gt 0 then tick_vals = [min_pos, tick_vals[wh_keep]]

     ;;    names = ['<0', '10!U' + strtrim(string(round(alog10(tick_vals))), 2) + '!N']

     ;; endif else names = '10!U' + strtrim(string(round(alog10(tick_vals))), 2) + '!N'
     if min(power_slice) lt 0 and min(tick_vals) lt min_pos then begin
        wh = where(tick_vals lt min_pos, count, complement = wh_keep, ncomplement = count_keep) 

        if count lt 1 then stop $
        else if count eq 1 then names = ['<0', '10!U' + strtrim(string(round(alog10(tick_vals[wh_keep]))), 2) + '!N'] $
        else names = [strarr(count-1), '<0', '10!U' + strtrim(string(round(alog10(tick_vals[wh_keep]))), 2) + '!N']

     endif else $
     names = '10!U' + strtrim(string(round(alog10(tick_vals))), 2) + '!N'

  endelse

  if (alog10(tick_vals[0]) - log_data_range[0]) gt 10^(-3d) then begin
     cb_ticknames = [' ', names]
     cb_ticks = [color_range[0], (alog10(tick_vals) - log_data_range[0]) * n_colors / $
                 (log_data_range[1] - log_data_range[0]) + color_range[0]] - color_range[0]
  endif else begin
     cb_ticknames = names
     cb_ticks = ((alog10(tick_vals) - log_data_range[0]) * n_colors / $
                 (log_data_range[1] - log_data_range[0]) + color_range[0]) - color_range[0]
  endelse

  if (log_data_range[1] - alog10(max(tick_vals))) gt 10^(-3d) then begin
     cb_ticknames = [cb_ticknames, ' ']
     cb_ticks = [cb_ticks, color_range[1]-color_range[0]]
  endif

  min_pos_cb_val = ((alog10(min_pos) - log_data_range[0]) * n_colors / $
                 (log_data_range[1] - log_data_range[0]) + color_range[0]) - color_range[0]
  cgcolorbar, color = annotate_color, /vertical, position = cb_pos, bottom = color_range[0], ncolors = n_colors+1, yminor = 0, $
              ticknames = cb_ticknames, ytickv = cb_ticks, yticks = n_elements(cb_ticks) -1, charsize = charsize, font = font

  if keyword_set(pub) and n_elements(multi_pos) eq 0 then begin
     psoff
     wdelete, window_num
  endif
  
  tvlct, r, g, b
  if keyword_set(all_zero) then temp = temporary(data_range)
  
end