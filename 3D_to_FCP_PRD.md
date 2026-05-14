## These are the requirements for the 3D to FCP app

## Purpose
The purpose of this app is to get a user's 3D object (always in the .USDZ format) into Final Cut Pro.

Currently the only way to get a USDZ file into Final Cut Pro is to put it into a Motion project and publish that project to Final Cut Pro.

This app automates that process.

## Customer experience

1. Customer launches the app. A window appears for dragging and dropping files along with a button for selecting files and instructions above the window "Add 3D objects in the USDZ format"
2. Customer drags USDZ file(s) onto an open window (or clicks a button to select and add them - one or more)
3. Customer click Go (or Create)
4. App confirms that the file(s) are created and tells the user where they can be found in Final Cut Pro (in the Titles Browser, in the "3D to FCP" category.

That's it. In Final Cut Pro, each USDZ appears in the Titles Browser in a new Category (temp name "3D to FCP"), and the filenames match the USDZ filenames. They drag one over a video like any other title and there are a variety of controls in the Title Inspector to adjust position, rotation, scale and animation, as well as build in and build outs.

## What the app needs to do

1. It checks to see if the user's computer contains a Motion templates folder at Home/Movies/Motion Templates. If the folder does not exist, it creates Motion Templates.localized and inside that it creates Titles.localized.
2. The app contains a Motion .moti project file that includes a "dummy" USDZ file. When the user clicks "Create", for each USDZ file they added, the app does the following:
	a. It duplicates the Motion .moti file
	b. It replaces the dummy USDZ file with the user's USDZ file
	c. It saves the Motion project file as a Title to users/movies/motion templates/titles/3D to FCP/filename.moti where "filename" is the name of the user's USDZ file.

## Design considerations
The app must be dead simple to use
The must look sleek, modern, and beautiful, incorporating the latest app design principles

