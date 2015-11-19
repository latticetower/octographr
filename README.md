Octographr
==========

This Sinatra-based app shows dependencies graph between classes in Scala source code in given github repository.

Motivation
----------

Sometimes I write in Scala (I don't publish that code - that's my own way to save the human race from it). One day I realized that my private github project has too much classes and too much dependencies between them. How to find bad code? I decided to build class diagrams and to look at them. I found couple of useful solutions, by they were able to build only basic dependencies between classes. I wanted to see some hidden dependencies.

And in Rails Rumble 2015 eve I thought, "that's a nice mini-project!". That's why this project is written in ruby and Sinatra-based.

I use `parslet` gem for parsing scala source code and `cytoscape.js` for drawing dependencies graph.  

Currently only public repositories are processed.
