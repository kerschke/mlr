#' @title Create model multiplexer for model selection to tune over multiple possible models.
#'
#' @description
#' Combines multiple base learners by dispatching
#' on the hyperparameter \dQuote{selected.learner} to a specific model class.
#' This allows to tune not only the model class (SVM, random forest, etc) but also
#' their hyperparameters in one go. Combine this with \code{\link{tuneParams}} and
#' \code{\link{makeTuneControlIrace}} for a very powerful approach, see example below.
#'
#' The parameter set is the union of all (unique) base learners.
#' In order to avoid name clashes all parameter names are prefixed
#' with the base learner id, i.e. \dQuote{[learner.id].[parameter.name]}.
#'
#' The predict.type of the Multiplexer is inherited from the predict.type of the
#' base learners.
#'
#' @param base.learners [\code{list} of \code{\link{Learner}}]\cr
#'  List of Learners with unique IDs.
#' @return [\code{ModelMultiplexer}]. A \code{\link{Learner}} specialized as \code{ModelMultiplexer}.
#' @aliases ModelMultiplexer
#' @family multiplexer
#' @family tune
#' @export
#' @note Note that logging output during tuning is somewhat shortened to make it more readable.
#'   I.e., the artificial prefix before parameter names is suppressed.
#' @examples
#' \donttest{
#' bls = list(
#'   makeLearner("classif.ksvm"),
#'   makeLearner("classif.randomForest")
#' )
#' lrn = makeModelMultiplexer(bls)
#' # simple way to contruct param set for tuning
#' # parameter names are prefixed automatically and the 'requires'
#' # element is set, too, to make all paramaters subordinate to 'selected.learner'
#' ps = makeModelMultiplexerParamSet(lrn,
#'   makeNumericParam("sigma", lower = -10, upper = 10, trafo = function(x) 2^x),
#'   makeIntegerParam("ntree", lower = 1L, upper = 500L)
#' )
#' print(ps)
#' rdesc = makeResampleDesc("CV", iters = 2L)
#' # to save some time we use random search. but you probably want something like this:
#' # ctrl = makeTuneControlIrace(maxExperiments = 500L)
#' ctrl = makeTuneControlRandom(maxit = 10L)
#' res = tuneParams(lrn, iris.task, rdesc, par.set = ps, control = ctrl)
#' print(res)
#' print(head(as.data.frame(res$opt.path)))
#'
#' # more unique and reliable way to construct the param set
#' ps = makeModelMultiplexerParamSet(lrn,
#'   classif.ksvm = makeParamSet(
#'     makeNumericParam("sigma", lower = -10, upper = 10, trafo = function(x) 2^x)
#'   ),
#'   classif.randomForest = makeParamSet(
#'     makeIntegerParam("ntree", lower = 1L, upper = 500L)
#'   )
#' )
#'
#' # this is how you would construct the param set manually, works too
#' ps = makeParamSet(
#'   makeDiscreteParam("selected.learner", values = extractSubList(bls, "id")),
#'   makeNumericParam("classif.ksvm.sigma", lower = -10, upper = 10, trafo = function(x) 2^x,
#'     requires = quote(selected.learner == "classif.ksvm")),
#'   makeIntegerParam("classif.randomForest.ntree", lower = 1L, upper = 500L,
#'     requires = quote(selected.learner == "classif.randomForst"))
#' )
#'
#' # all three ps-objects are exactly the same internally.
#' }
makeModelMultiplexer = function(base.learners) {
  lrn = makeBaseEnsemble(
    id = "ModelMultiplexer",
    base.learners = base.learners,
    bls.type = NULL,
    ens.type = NULL,
    cl = "ModelMultiplexer"
  )
  # the super contructor checks that all predict.types are same
  # now inherit this type from the base.learners for the MM
  lrn = setPredictType(lrn, lrn$base.learners[[1L]]$predict.type)
  # add extra param to parset, after we did all checks and so on in the base function
  ps = makeParamSet(makeDiscreteLearnerParam("selected.learner", values = names(lrn$base.learners)))
  lrn$par.set = c(lrn$par.set, ps)
  lrn$par.set.ens = ps
  lrn$fix.factors.prediction = TRUE
  setHyperPars(lrn, selected.learner = names(lrn$base.learners)[1L])
}

#' @export
trainLearner.ModelMultiplexer = function(.learner, .task, .subset, .weights = NULL, selected.learner, ...) {
  # train selected learner model and remove prefix from its param settings
  bl = .learner$base.learners[[selected.learner]]
  m = train(bl, task = .task, subset = .subset, weights = .weights)
  makeChainModel(next.model = m, cl = "ModelMultiplexerModel")
}

#' @export
predictLearner.ModelMultiplexer = function(.learner, .model, .newdata, ...) {
  # simply predict with the model
  sl = .learner$par.vals$selected.learner
  bl = .learner$base.learners[[sl]]
  # we need to pass the changed setting of the base learner for the predict function further down
  args = list(.learner = bl, .model = .model$learner.model$next.model, .newdata = .newdata)
  args = c(args, getHyperPars(bl, for.fun = "predict"))
  do.call(predictLearner, args)
}

#' @export
makeWrappedModel.ModelMultiplexer = function(learner, learner.model, task.desc, subset, features, factor.levels, time) {
  addClasses(NextMethod(), "ModelMultiplexerModel")
}

#' @export
getLearnerModel.ModelMultiplexerModel = function(model, more.unwrap = FALSE) {
  if (more.unwrap)
    model$learner.model$next.model$learner.model
  else
    model$learner.model$next.model
}

#' @export
isFailureModel.ModelMultiplexerModel = function(model) {
  isFailureModel(model$learner.model$next.model)
}

