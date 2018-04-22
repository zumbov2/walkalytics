#' @importFrom sp CRS GridTopology SpatialGridDataFrame
#'
#' @noRd
read_asc_gz_to_grid <- function (fname, as.image = FALSE, plot.image = FALSE, colname = fname) {

  t = gzcon(file(fname, "rb"))
  l5 = readLines(t, n = 6)
  l5s = strsplit(l5, "\\s+", perl = T)
  xllcenter = yllcenter = xllcorner = yllcorner = as.numeric(NA)
  for (i in 1:6) {
    fieldname = casefold(l5s[[i]][1])
    if (length(grep("ncols", fieldname)))
      ncols = as.numeric(l5s[[i]][2])
    if (length(grep("nrows", fieldname)))
      nrows = as.numeric(l5s[[i]][2])
    if (length(grep("xllcorner", fieldname)))
      xllcorner = as.numeric(l5s[[i]][2])
    if (length(grep("yllcorner", fieldname)))
      yllcorner = as.numeric(l5s[[i]][2])
    if (length(grep("xllcenter", fieldname)))
      xllcenter = as.numeric(l5s[[i]][2])
    if (length(grep("yllcenter", fieldname)))
      yllcenter = as.numeric(l5s[[i]][2])
    if (length(grep("cellsize", fieldname)))
      cellsize = as.numeric(l5s[[i]][2])
    if (length(grep("nodata_value", fieldname)))
      nodata.value = as.numeric(l5s[[i]][2])
  }
  if (is.na(xllcorner) && !is.na(xllcenter))
    xllcorner = xllcenter - 0.5 * cellsize
  else xllcenter = xllcorner + 0.5 * cellsize
  if (is.na(yllcorner) && !is.na(yllcenter))
    yllcorner = yllcenter - 0.5 * cellsize
  else yllcenter = yllcorner + 0.5 * cellsize
  map = scan(t, as.numeric(0), quiet = TRUE)
  close(t)
  if (length(as.vector(map)) != nrows * ncols)
    stop("dimensions of map do not match that of header")
  map[map == nodata.value] = NA
  df = data.frame(map)
  names(df) = colname
  grid = sp::GridTopology(c(xllcenter, yllcenter), rep(cellsize, 2), c(ncols, nrows))
  sp::SpatialGridDataFrame(grid, data = df, proj4string = sp::CRS(as.character(NA)))

}
