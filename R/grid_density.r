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



#' Pulse density surface model
#'
#' Creates a pulse density map using a LiDAR cloud of points. This function is an alias
#' for \code{grid_metrics(obj, res, length(unique(pulseID))/res^2)}.
#'
#' @aliases grid_density
#' @param obj An object of class \code{LAS}
#' @param res numeric. The size of a grid cell in LiDAR data coordinates units. Default is 4 units i.e. 16 square units cells.
#' @return It returns a \code{data.table} of the class \code{grid_metrics} which enables easier plotting.
#' @examples
#' LASfile <- system.file("extdata", "Megaplot.laz", package="lidR")
#' lidar = readLAS(LASfile)
#'
#' lidar %>% grid_density(5) %>% plot
#' lidar %>% grid_density(10) %>% plot
#' @family grid_alias
#' @seealso
#' \link[lidR:grid_metrics]{grid_metrics}
#' @export grid_density
grid_density = function(obj, res = 4)
{
  pulseID <- density <- X <- NULL

  if(! "pulseID" %in% names(obj@data))
  {
    warning("No column named pulseID found. The pulse density cannot be computed. Computes the point density instead of the pulse density.", call. = F)
    ret = grid_metrics(obj, res, list(density = length(X)/res^2))
  }
  else
  {
    ret = grid_metrics(obj, list(density = length(unique(pulseID))/res^2), res)
  }

  return(ret)
}