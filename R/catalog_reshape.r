# ===============================================================================
#
# PROGRAMMERS:
#
# jean-romain.roussel.1@ulaval.ca  -  https://github.com/Jean-Romain/lidR
#
# COPYRIGHT:
#
# Copyright 2016 Jean-Romain Roussel
#
# This file is part of lidR R package.
#
# lidR is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# ===============================================================================




#' Reshape (retile) a catalog
#'
#' The function split or merge files to reshape original files (las or laz) of a catalog
#' in smaller or bigger files. The new files are written in a dedicated folder. The function
#' first display the pattern of the new tiling and asks the user to validate the command.
#'
#' @param ctg  A \link[lidR:catalog]{Catalog} object
#' @param size scalar. The size of the new tiles
#' @param path string. The folder where to save the new files
#' @param prefix character. The initial part of the name of the written files
#' @param ext character. Format of the written files. Can be "las" or "laz".
#'
#' @return A new catalog object
#' @seealso \link{catalog}
#' @export
#' @examples
#' \dontrun{
#' ctg = catalog("path/to/catalog")
#'
#' # Will create a new set of las files 500 by 500 wide in the folder
#' # path/to/new/catalog/ and iteratively named Forest_1.las, Forest_2.las
#' # Forest_3.las and so on.
#' newctg = catalog_reshape(ctg, 500, "path/to/new/catalog", "Forest_")
#' }
catalog_reshape = function(ctg, size, path, prefix, ext = c("las", "laz"))
{
  ext <- match.arg(ext)

  ncores = CATALOGOPTIONS("multicore")

  # Create a pattern of clusters to be sequentially processed
  ctg_clusters = catalog_makecluster(ctg, 1, 0, FALSE, size)
  ctg_clusters = apply(ctg_clusters, 1, as.list)

  text = paste0("This is how the catalog will be reshaped. Do you want to continue?")
  choices = c("yes","no")

  cat(text)
  choice = utils::menu(choices)

  if (choice == 2)
    return(invisible(NULL))

  if(!dir.exists(path))
    dir.create(path, recursive = TRUE)

  files <- list.files(path, pattern = "(?i)\\.la(s|z)$")

  if(length(files) > 0)
    stop("The output folder already contains las or laz files. Operation aborted.")

  ti = Sys.time()

  # Computations done within sequential or parallel loop in .getMetrics
  if (ncores == 1)
  {
    output = lapply(ctg_clusters, reshape_func, path = path, prefix = prefix, ext = ext)
  }
  else
  {
    cat("Begin parallel processing... \n")
    cat("Num. of cores:", ncores, "\n\n")

    cl = parallel::makeCluster(ncores, outfile = "")
    parallel::clusterExport(cl, varlist = c(utils::lsf.str(envir = globalenv()), ls(envir = environment())), envir = environment())
    output = parallel::parLapply(cl, ctg_clusters, fun = reshape_func, path = path, prefix = prefix, ext = ext)
    parallel::stopCluster(cl)
  }

  tf = Sys.time()
  cat("Process done in", round(difftime(tf, ti, units="min"), 1), "min\n\n")

  return(catalog(path))
}

reshape_func = function(cluster, path, prefix, ext)
{
  X <- Y <- NULL

  # Variables for readability
  xcenter = cluster$xcenter
  ycenter = cluster$ycenter
  xleft   = cluster$xleft
  xright  = cluster$xright
  ybottom = cluster$ybottom
  ytop    = cluster$ytop
  name    = cluster$name
  width   = (xright - xleft)/2

  path = paste0(path, "/", prefix, name , ".", ext)

  # Extract the ROI as a LAS object
  las = catalog_queries_internal(
            obj = ctg,
            x = xcenter,
            y = ycenter,
            r = width,
            r2 = width,
            buffer = 0,
            roinames = name,
            filter = "",
            ncores = 1,
            progress = FALSE,
            ScanDirectionFlag = TRUE,
            EdgeOfFlightline = TRUE,
            UserData = TRUE,
            PointSourceID = TRUE,
            pulseID = FALSE)[[1]]

  # Skip if the ROI fall in a void area
  if (is.null(las))
    return(NULL)

  # Because catalog_queries keep point inside the boundingbox (close interval) but point which
  # are exactly on the boundaries are counted twice. Here a post-process to make an open
  # interval on left and bottom edge of the boudingbox.
  n = fast_countequal(las@data$X, xleft) + fast_countequal(las@data$Y, ybottom)

  if (n > 0)
    las = suppressWarnings(lasfilter(las, X > xleft, Y > ybottom))

  # Very unprobable but who knows...
  if (is.null(las))
    return(NULL)

  writeLAS(las, path)

  return(NULL)
}