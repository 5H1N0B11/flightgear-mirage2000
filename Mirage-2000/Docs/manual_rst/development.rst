:orphan:

***********
Development
***********


Generating the Manual
=====================

Pre-requisites
--------------

Create a local Pythong virtual environment on Ubuntu:

::

    user$ apt install python3 python3-venv
    user$ python3 -m venv /home/vanosten/bin/virtualenvs/m2000
    user$ source /home/vanosten/bin/virtualenvs/m2000/bin/activate
    (m2000) user$ cd /home/vanosten/flightgear-mirage2000/Docs/manual_rst

    (o2c312) user$ pip3 install -r requirements.txt


Executing the Generation Proces
-------------------------------

Follow the following for generating the manual:

* Create the pdf file locally: Issue command ``sphinx-build -b rinoh . build``
* Copy/overwrite the generated file ``mirage2000-new-manual.pdf`` from the ``build`` directory to the root ``Docs`` folder.


Convention for Section Styling
------------------------------

The following style for titles/sections is used: ``Section conventions⇗ <https://documatt.com/restructuredtext-reference/element/section.html#section-conventions>``.

* L1: Document title ``####`` (above and below - not used)
* L2: Chapters ``****`` (above and below)
* L3: Sections ``====`` (below)
* L4: Subsections ``----`` (below)
* L5: Subsubsections ``^^^^`` (below)
* L6: Paragraphs ``''''`` (below)


Nasal Programming Conventions
=============================

The FlightGear documentation for `Nasal⇗ <https://wiki.flightgear.org/Nasal_scripting_language>`_ does not have general conventions. Therefore, the following states the opinionated conventions used by the currently most active developer. NB: A lot of code does not yet follow these conventions, because it was written earlier.

Naming Conventions
------------------

* Immutable variables: ALL_CAPS (uppercase and underscores - e.g. COLOUR_GREEN)
* Other variables: snake_case (lowercase and underscores - e.g. ripple_mode)
* Classes: PascalCase
* Methods and functions: camelCase
* "private" methods and functions: start with underscore (e.g. _changeRippleMode()). Like in Python this is just a convention, not enforced. "Private" means here: within a class or the file.

Booleans
--------

In each module, where booleans are handled, create the immutable variables ``TRUE = 1`` and ``FALSE = 0`` and use them consequently in the code instead of ``1`` and ``0``.

Indentation
-----------

* Use tabs covering 4 spaces.
* Use spaces after tabs for aligning lines when using a builder pattern (e.g. for Canvas).

Spacing
-------

* Use space in front of curly braces.
* Use space between key words and parentheses (e.g. ``if (`` ).


XML Conventions
===============

* Encoding = ``<?xml version="1.0" encoding="utf-8"?>``
* Use tabs covering 4 spaces.
