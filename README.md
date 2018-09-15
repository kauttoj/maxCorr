# maxCorr
maxCorr method to clean multivariate signals, via removal of individual (noise) components while retaining the shared components signals. For example, use it to remove subject-specific motion and physiological noise from fMRI data, which was collected with the same time-locked stimulus (e.g., movie) that was same for all subjects.

This is a modified version of the code originally published by the authors of the following paper (all credit goes to them):
Pamilo, S. , Malinen, S. , Hotta, J. , Seppä, M. and Foxe, J. (2015), A correlation‐based method for extracting subject‐specific components and artifacts from group‐fMRI data. Eur J Neurosci, 42: 2726-2741. doi:10.1111/ejn.13034
