# Configuration file for the Sphinx documentation builder.

# -- Project information -----------------------------------------------------
project = 'FlightGear Mirage 2000'
copyright = '2025, FlightGear Mirage 2000 Team'
author = 'Rick Gruber-Riemer, Renaud Roquefort'
release = '0.0.1'

# -- General configuration ---------------------------------------------------
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

source_suffix = '.rst'
master_doc = 'index'

language = 'en'

pygments_style = 'sphinx'


# -- Options for HTML output -------------------------------------------------
html_theme = 'sphinx_rtd_theme'
# html_static_path = ['_static']
htmlhelp_basename = 'M2000doc'


# -- Options for rinohtype (direct PDF) output -----------------------------------
# https://www.mos6581.org/rinohtype/master/sphinx.html
rinoh_documents = [
    dict(doc='index', target='mirage2000-new-manual', title='FlightGear Mirage 2000-5/2000D Manual', subtitle='',
         toctree_only=False, domain_indices=False, template='article')
]
