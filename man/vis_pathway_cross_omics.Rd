% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vis_cross.R
\name{vis_pathway_cross_omics}
\alias{vis_pathway_cross_omics}
\title{Visualize cross-omics of one pathway among pan-cancers}
\usage{
vis_pathway_cross_omics(
  pw = "HALLMARK_ADIPOGENESIS",
  tumor_projects = NULL,
  tumor_samples = NULL,
  pval_mrna = c(0.05, 0.01, 0.001),
  return_list = FALSE
)
}
\arguments{
\item{pw}{pathway name}

\item{tumor_projects}{Select specific TCGA projects. Default NULL, indicating all TCGA projects.}

\item{tumor_samples}{Select specific tumor samples. Default NULL, indicating all tumor samples.}

\item{pval_mrna}{The P value thresholds}

\item{return_list}{TRUE returns a list including plot object and data. FALSE just returns plot.}
}
\value{
funkyheatmap
}
\description{
Visualize cross-omics of one pathway among pan-cancers
}
