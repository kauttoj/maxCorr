# maxCorr
maxCorr method to clean multivariate signals, via removal of individual (noise) components while retaining the shared components signals. For example, use it to remove subject-specific motion and physiological noise from fMRI data, which was collected with the same time-locked stimulus (e.g., movie) that was same for all subjects.

In this modified version the number of signals (e.g., voxels) per subject does not need to be equal. This has an effect on the estimation of the threshold associated with the total count of meaningful noise components. Now the threshold is based on the mean signal count.

This is a modified version of the code originally published by the authors of the following paper (all credits to them):
Pamilo, S. , Malinen, S. , Hotta, J. , Seppä, M. and Foxe, J. (2015), A correlation‐based method for extracting subject‐specific components and artifacts from group‐fMRI data. Eur J Neurosci, 42: 2726-2741. doi:10.1111/ejn.13034
