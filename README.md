# Optotrack

<img src="http://bradleymonk.com/dropbox/img/optotracklogo.png" alt="Optotrack Software" width="500" border="10" />

## About

The goal of this project is to write code to track a rodent in real time (30 fps) with a high level of accuracy. Ideally, the code will identify 1) where the animal is 2) in what direction it is facing 3) how fast it is moving 4) SMP values 5) location of head/nose 6) body elongation.


The optotrack program is run from optotrack.m that initializes a GUI interface, and strings together to several video processing functions. First it runs the IRframes() function to perform basic tracking. This involves finding the nth hottest pixels and takes their centroid as the location of the animal. Despite its simplicity, it works fairly well -- mostly tracking the animal's head due to the heat radiating off the headcap. It outputs tracking data (xy), speed (dL), as well as the first frame of the video (image) to draw ROIs. After that, IRtrack() function is called, which tracks the animal using some tools from MATLAB's image analysis toolbox. As of now, it:

1. Tracks animal based on location of head, center of mass, or outline.
2. Triggers function based on location within user-defined ROI
3. Generate pulses to drive optogenetics laser


## Goals

The project goals can be defined as follows:

1. Fine tune the tracking process (this is only an initial 'go') and streamline the process to work live at 30 fps -- not everything has to be done online, only the location of the animal's head
2. Use this information to generate pulses that are exported via the DAQ for optogenetic experiments
3. Line up fiber photometry data to video and create environment that allows for video annotation (would be nice to see fiber photometry data live -- which shouldn't be too hard as they are only 2 points)


## Resources
* [Computational Geometry Algorithm Library](http://www.cgal.org/)
* [Brad's GitHub Demo](http://www.bradleymonk.com/Github)
* [GitHub readme formatting markdown cheatsheet][1]

[1]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet

