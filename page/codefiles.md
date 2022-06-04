
@def title       = """Codes (written in <a href="https://julialang.org" class="julia_button">Julia</a>)"""
@def description = """<a href="https://alfaromartino.github.io/nace4europe/" class="julia_button">Back to Main Page</a> """



<!--  NAVBAR SPECS
  NOTE:
  - add_docs:  whether to add a pointer to your docs website
  - docs_url:  the url of the docs website (ignored if add_docs=false)
  - docs_name: how the link should be named in the navbar

  - add_nav_logo:  whether to add a logo left of the package name
  - nav_logo_path: where the logo is
-->
@def add_docs  = false
@def docs_url  = "https://franklinjl.org/"
@def docs_name = "Docs"

@def add_nav_logo   = false
@def nav_logo_path  = "/assets/logo.svg"
@def nav_logo_alt   = "Logo"
@def nav_logo_style = """
                      height:         25px;
                      padding-right:  10px;
                      """

@def use_header         = true
@def use_header_img     = false
@def header_img_path    = "url(\"assets/diag2.jpg\")"
@def header_img_style   = """
                          background-repeat: repeat;
                          """
@def header_margin_top  = "0px" <!-- 55-60px ~ touching nav bar, ME: set 0 if I disable the navigation bar -->

@def use_hero           = false
@def hero_width         = "90%"
@def hero_margin_top    = "100px"


@def header_color       = "#3f6388"
@def link_color         = "#2669DD"
@def link_hover_color   = "teal"
@def section_bg_color   = "#f6f8fa"
@def footer_link_color  = "cornflowerblue"

<!-- options "atom-one-dark" or "vs" or "github"; use lower case and replace -->
@def highlight_theme    = "atom-one-dark"
@def code_border_radius = "10px"
@def code_output_indent = "0px"


<!-- INTERNAL DEFINITIONS =====================================================
===============================================================================
These definitions are important for the good functioning of some of the
commands that are defined and used in PkgPage.jl
-->
@def sections        = Pair{String,String}[]
@def section_counter = 1
@def showall         = false


\newcommand{\html}[1]{~~~#1~~~}
\newenvironment{center}{\html{<div style="text-align:center;">}}{\html{</div>}}
\newenvironment{columns}{\html{<div class="container"><div class="row">}}{\html{</div></div>}}


<!--
============== 
PAGE
==============
-->


\begin{section}{title="Code Overview ", name="content"}
The code consists of three files:\\
(1) [`main.jl`](#mainfile) \\
(2) [`RelativeShare42.jl`](#share42) \\
(3) [`RelativeShare21.jl`](#share21) 

To describe the code, I refer to an _industry_ as a NACE 4-digits industry, a _sector_ by a NACE 2-digits industry., and _manufacturing_ by all sectors. The file `RelativeShare42.jl` computes revenue shares for each country-year-industry relative to its country-year-sector. The file `RelativeShare21.jl`does the same, but for each country-year-sector relative to manufacturing in each country-year. The file `main.jl` gathers all the results. 

Running the code requires turnover data from Eurostat, which can be found [here](https://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=sbs_na_ind_r2&lang=en). It additionally builds on revenue information from companies obtained through the [ORBIS dataset](https://www.bvdinfo.com/en-gb/our-products/data/international/orbis). This information is proprietary, and I cleaned it before its use. 

\end{section}


\begin{section}{title="`main.jl`"}\label{mainfile}
\input{julia}{/_assets/scripts/main.jl} 

\end{section}


\begin{section}{title="`RelativeShare42.jl`", name="content2"} \label{share42}
The following is the procedure for computing a 4-digits Industry's Revenue Share relative to its 2-digits sector. It provides an industry's revenue share at 4-digits level *relative to* its 2-digits sector. 
 
\input{julia}{/_assets/scripts/RelativeShare42.jl} <!--_-->
```julia
```




\end{section}





\begin{section}{title="`RelativeShare21.jl`"}\label{share21}
The following is the procedure for computing a 2-digits sector's revenue share relative to manufacturing.

\input{julia}{/_assets/scripts/RelativeShare21.jl} <!--_-->

\end{section}

