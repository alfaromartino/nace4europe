<!-- =============================
     ABOUT
    ============================== -->
\begin{section}{title="Contents", name="content"}
(1) [Relevance of the Estimates](#summ) \\
(2) [Links for Downloading the Estimates](#sec0) \\

The estimates have been derived using \figure{path="/assets/logo_julia.png", width="10%", style="border-radius:2px;"}
and this page was created using [PkgPage.jl](https://github.com/tlienart/PkgPage.jl)
\end{section}

<!-- ==============================
     SUMMARY
     ============================== -->
\begin{section}{title="Relevance of the Estimates"}\label{summ}
Eurostat provides official statistics for revenue of industries in the **manufacturing sector** (sector C, with codes from 1000 to 3399, as defined by the NACE rev 2 classification). They are presented in the dataset `sbs_na_ind_r2`. \\

The **issue** we face is that not all values are reported due to confidentiality matters. This is even more pervasive for the total production reported by Prodcom classification (dataset `DS-066342`), which is dissagregated at the 8-digit level. \\

Attending to this, this page provides estimates of revenue for 19 European countries. They consider the year 2018 and report revenues at the NACE (rev. 2) 4-digit level. The completion is based on an iterative procedure that recovers revenue shares within manufacturing, through the following steps for each country:
1. Based on the revenues by Eurostat in Euros, define
	&ensp; &ensp; &ensp; (a) revenue shares at the 2-digit level relative to manufacturing, and \\
	&ensp; &ensp; &ensp; (b) revenue shares at the 4-digit level relative to the industry's 2-digit level.
2. Given remaining missing shares in (a) and (b), define relative shares based on previous years. To improve accuracy, the completion of relative shares are performed at the 4- and 2-digit level separately.
1. If there are still missing shares, we use information from the [ORBIS dataset](https://www.bvdinfo.com/en-gb/our-products/data/international/orbis). This exploits that ORBIS reports each firm's revenue at the NACE 4-digit level, allowing us to compute any remaining relative share at the 4- and 2-digit levels.\\

The **countries** covered are Bulgaria, Croatia, Czech Republic, Finland, France, Germany, UK, Hungary, Italy, 
Norway, Poland, Portugal, Romania, Serbia, Slovakia, Slovenia, Spain, Sweden, and Ukraine. 

The countries chosen have a high coverage in ORBIS relative to Eurostat (except for Germany, which I included given its importance). The following tables show the percentage of revenue covered by ORBIS in each country. \\ \\

\begin{center}
\figure{path="/assets/scripts/ind_rev_orbis_west.svg", width="150%", style="border-radius:2px;"}
\figure{path="/assets/scripts/ind_rev_orbis_east.svg", width="150%", style="border-radius:2px;"}
\end{center}



\end{section}


<!-- ==============================
     ESTIMATES
     ============================== -->
\begin{section}{title="Links for Downloading the Estimates"}\label{sec0}
Estimates at the 4-digit level are [here](https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace4.csv). `rev4` indicates the value in Euros, and `share4` the revenue share within a country's manufacturing revenue. \\
Estimates at the 2-digit level are [here](https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace2.csv). `rev2` indicates the value in Euros, and `share2` the revenue share within a country's manufacturing revenue.\\

All files are in CSV format and you can also access the files directly: \\
In **Julia** 

```julia
using CSV, Downloads
nace4 = DataFrame(CSV.File(Downloads.download("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace4.csv"))) 
nace2 = DataFrame(CSV.File(Downloads.download("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace2.csv")))
```

In **R**
```Python
nace4 <- read.csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace4.csv")
nace2 <- read.csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace2.csv")
```

In **Python**
```Python
import pandas as pd
nace4 = pd.read_csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace4.csv")
nace2 = pd.read_csv("https://raw.githubusercontent.com/alfaromartino/nace4europe/main/page/_assets/euro_nace2.csv")
```




\end{section}


