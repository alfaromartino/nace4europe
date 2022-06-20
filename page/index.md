@def highlight_theme    = "atom-one-dark"
@def code_border_radius = "15px"
@def code_output_indent = "2px"

<!-- =============================
     ABOUT
    ============================== -->
\begin{section}{title="Contents", name="content"}
(1) [Relevance of the Estimates](#summ) \\
(2) [Links to Download the Estimates](#sec0) \\
(3) [Link to Codes](/codefiles/) written in ~~~<img src="/assets/logo_julia.png" width="10%"  />~~~&ensp; and further details. \\
\end{section}


<!-- ==============================
     RELEVANCE OF THE ESTIMATES
     ============================== -->
\begin{section}{title="Relevance of the Estimates"}\label{summ}

<!--
~~~
<link rel="stylesheet" type="text/css"
    href="https://cdn.rawgit.com/dreampulse/computer-modern-web-font/master/fonts.css">
<style>
body {
  font-family: "Computer Modern Serif", sans-serif;
}
</style>
~~~
-->

Eurostat's dataset `sbs_na_ind_r2` provides official statistics for revenue in the **manufacturing sector** (sector C, with codes from 1000 to 3399 as defined by the NACE rev. 2 classification). They come from  its [Structural Business Statistics](https://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=sbs_na_ind_r2&lang=en) (SBS). The **issue** is that these values aren't reported for all industries, due to confidentiality matters. 

Attending to this, I provide revenue estimates for several European countries at the NACE (rev. 2) 4-digits level. The data are at the **cross-section level**, for each year between **2012-2019**.  The completion for each year is based on an iterative procedure, using Eurostat's information from other years and the [ORBIS dataset](https://www.bvdinfo.com/en-gb/our-products/data/international/orbis). 

The procedure consists of the following steps. Define an _industry_ by its NACE 4 digits, a _sector_ by its NACE 2 digits, and _manufacturing_ by the sum of all sectors belonging to the 2-digits codes 10 to 33. Then, for each country and year:
1. Based on Eurostat's revenues for that specific year, I identify:\\
     &ensp; &ensp; &ensp; (a) each sector's revenue share relative to manufacturing, \\
     &ensp; &ensp; &ensp; (b) each industry's revenue share relative to its sector.
2. Taking those shares, I compute the missing shares in (a) and (b). The completion of shares is performed separately by industries and sectors to improve accuracy. This means that any imprecision at the industry level is not transmitted to the sector shares. Specifically, I compute missing shares by:\\
     &ensp; &ensp; &ensp; (a) using relative shares from contiguous years in Eurostat's data,\\
     &ensp; &ensp; &ensp; (b) if there are still missing shares, I use information from ORBIS. This exploits that ORBIS reports each firm's revenue at the NACE 4-&ensp; &ensp; &ensp; &ensp; &ensp; &ensp; digits level, making it possible to compute any remaining relative share at the industry and sector level.



The estimates are especially relevant for the years 2016-2018, since ORBIS' information has been improving over the years (2019 has the issue of only using previous years from Eurostat rather than contiguous ones, to avoid using data from the pandemic). Furthermore, the data richness of ORBIS depends on the country considered, since its coverage varies by country. \\

ORBIS coverage is particularly rich for the following **countries**:  Bulgaria, Croatia, Czech Republic, Finland, France, UK, Hungary, Italy, Norway, Poland, Portugal, Romania, Serbia, Slovakia, Slovenia, Spain, and Sweden. On the contrary, Germany's coverage in ORBIS is relatively low, despite its importance. The following tables show each country's revenue in ORBIS relative to Eurostat for the year 2018.


~~~
<div style="text-align:center;">
<img src="/assets/scripts/without_german.svg" width="70%" />
<div style="text-align:justify;">
~~~
\\
\\
See [here](/codefiles/) for further details about the code and the procedure.

\end{section}


<!-- ==============================
     ESTIMATES
     ============================== -->
     
\begin{section}{title="Links to Download the Estimates"}\label{sec0}

     
The estimates are in CSV format and can be downloaded [HERE](https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/RevenueManufacture_NACE4.csv). The description of variables is provided in this [README.txt](https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/readme.txt). It's worth emphasizing that the information covers the years 2012-2019, but it's cross-section&mdash;it is NOT panel data. \\ 

You can also access the data directly: 

in **Julia** 

```julia
using CSV, Downloads, DataFrames
dataset = DataFrame(CSV.File(Downloads.download("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/RevenueManufacture_NACE4.csv"))) 

```

in **R**
```Python
dataset <- read.csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/RevenueManufacture_NACE4.csv")

```

in **Python**


```Python
import pandas as pd
dataset = pd.read_csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/RevenueManufacture_NACE4.csv")

```

\end{section}


