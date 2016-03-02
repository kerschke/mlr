#' @title Update learner according to the task.
#'
#' @description Update learner according to the task.
#' @template arg_learner
#' @template arg_task
#' @return [\code{\link{Learner}}].
#' @export
adaptLearnerToTask = function(lrn, task) {
  ee = makeEnvironmentFromTask(task)
  checkLearnerParset(lrn$par.set, envir = ee)
  lrn$par.set = ParamHelpers::evaluateParamSet(par.set = lrn$par.set, envir = ee)
  return(lrn)
}
