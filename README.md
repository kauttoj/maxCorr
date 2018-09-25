# maxCorr
25.9.2018

maxCorr method to clean multivariate signals via removal of individual (noise) components while retaining the shared components signals. For example, use it to remove subject-specific motion and physiological noise from fMRI data, which was collected with the same time-locked stimulus (e.g., movie) same for all subjects.

In this modified version, the number of signals (e.g., voxels) per subject does not need to be equal. This affects the parametric estimation of the threshold associated with the total count of meaningful common signal components. Here the threshold is based on the mean signal count over other subjects. I have also added option to use slower, non-parametric permutations to estimate common component count, which typically lead to more aggressive cleaning (smaller common space). I have added functions to process large fMRI datasets efficiently in parallel using grid computing.

Main parts of the code was written and published by the authors of the following paper (all credits and citations should go to them):
Pamilo, S. , Malinen, S. , Hotta, J. , SeppÃ¤, M. and Foxe, J. (2015), A correlationâ€based method for extracting subjectâ€specific components and artifacts from groupâ€fMRI data. Eur J Neurosci, 42: 2726-2741. doi:10.1111/ejn.13034

