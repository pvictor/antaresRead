#Copyright © 2016 RTE Réseau de transport d’électricité

# Copy the test study in a temporary folder

path <- tempdir()
sourcedir <- system.file("inst/testdata", package = "antaresRead")
testH5 <- TRUE
if(sourcedir == ""){ sourcedir <- system.file("testdata", package = "antaresRead")}

## force tests to be executed if in dev release which we define as
## having a sub-release, eg 0.9.15.5 is one whereas 0.9.16 is not
## we test dev version locally, on travis and appveyor but not in CRAN
if (length(strsplit(packageDescription("antaresRead")$Version, "\\.")[[1]]) > 3) { 
  Sys.setenv("RunAllAntaresReadTests"="yes")
}
.runH5Test <- Sys.getenv("RunAllAntaresReadTests") == "yes"


# Hack: For some unknown reason, this script is executed at some point of
# the R CMD CHECK before package is correctly installed and tests actually run. 
# The following "if" prevents errors at this step
if (sourcedir != "") {
  if (Sys.info()['sysname'] == "Windows") {
    untar(file.path(sourcedir, "antares-test-study.tar.gz"), exdir = path, 
          extras = "--force-local")
  } else {
    untar(file.path(sourcedir, "antares-test-study.tar.gz"), exdir = path)
  }
  
  if(.requireRhdf5_Antares(stopP = FALSE) & .runH5Test){
    
    opts <- setSimulationPath(file.path(path, "/test_case"))
    suppressMessages({
      suppressWarnings({

        #On cran we have only 2 threads so nbCore <- 1  
        if(.runH5Test){
          nbCoresTestHelper<-4
        }else{
          nbCoresTestHelper<-1
        }
        writeAntaresH5(path = path, 
                       misc = TRUE, thermalAvailabilities = TRUE,
                       hydroStorage = TRUE, hydroStorageMaxPower = TRUE, reserve = TRUE,
                       linkCapacity = TRUE,mustRun = TRUE, thermalModulation = TRUE,
					   overwrite=TRUE, nbCores = nbCoresTestHelper)
      })
    })
    
    #if you change the tar file then you must also change this file
    h5file <- "20180423-1734eco-test.h5"
    
    deprintize<-function(f){
      return(function(...) {capture.output(w<-f(...));return(w);});
    }
    
    silentf <- deprintize(showAliases)
    
    alias <- silentf()$name
    alias <- as.character(alias)
    
    compareValue <- function(A, B, res = NULL){
      if(class(A)[3] == "list"){
        res <- c(res, sapply(c("areas", "links", "cluster", "districts"), function(x){
          if(!is.null(A[[x]]))
          {
            compareValue(A[[x]], B[[x]], res = res)}}))
        
      }else{
        res <- c(res,sapply(names(A), function(X){
          if(identical(A[[X]], B[[X]])){
            TRUE
          }else{
            if(class(A[[X]]) %in% c("integer", "numeric")){
              if(identical(as.numeric(A[[X]]), as.numeric(B[[X]]))){
                TRUE
              } else {
                FALSE
              }
            } else if(class(A[[X]]) %in% c("character", "factor")){
              if(identical(as.character(A[[X]]), as.character(B[[X]]))){
                TRUE
              } else {
                FALSE
              }
            } else {
              FALSE
            }
          }
        }))
      }
    }
    
    timeStep <-  c("hourly", "daily", "weekly", "monthly", "annual")
    
    assign("silentf", silentf, envir = globalenv())
    assign("tpDir", path, envir = globalenv())
    assign("pathF", file.path(path, "/", h5file), envir = globalenv())
    assign("h5file", h5file, envir = globalenv())
    assign("alias", alias, envir = globalenv())
    assign("compareValue", compareValue, envir = globalenv())
    assign("timeStep", timeStep, envir = globalenv())
    assign("optsG", opts, envir = globalenv())
    
    assign("studyPathS", c(file.path(path), file.path(path, "test_case")), envir = globalenv())
    
  } else {
    assign("studyPathS", file.path(path, "test_case"), envir = globalenv())
  }
  
  assign("nweeks", 2, envir = globalenv())
  assign("nmonths", 2, envir = globalenv())
  assign("firstDay", 113, envir = globalenv())
  assign("lastDay", 126, envir = globalenv())
}
