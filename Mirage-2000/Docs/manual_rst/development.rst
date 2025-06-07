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

The following style for titles/sections is used: ``Section conventions <https://documatt.com/restructuredtext-reference/element/section.html#section-conventions>``.

* L1: Document title ``####`` (above and below - not used)
* L2: Chapters ``****`` (above and below)
* L3: Sections ``====`` (below)
* L4: Subsections ``----`` (below)
* L5: Subsubsections ``^^^^`` (below)
* L6: Paragraphs ``''''`` (below)
