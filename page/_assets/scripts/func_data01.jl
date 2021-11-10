using DataFrames
using CSV
using StatFiles



#cd("$(homedir())\\Google Drive\\MY-PAPERS\\empirical-melitz\\julia\\intuitions\\graph")
#a=read_dta("C:\\Users\\marti\\Desktop\\compnet\\jd_TD14_exp_country_weighted_all.dta")
#df = DataFrame(load("C:\\Users\\marti\\Desktop\\compnet\\jd_TD14_exp_country_weighted_all.dta"))






######################################################################################
####################													###############################
################ 				FUNCTIONS TO CLEAN VARIABLES			 ##############################
#################													#############################
######################################################################################

#### the functions take a dataset as an argument
### we take 2018 as our baseline year (reflected in alternativa values from 2019 and 2017)

function data(ctry)

function clean(dg,dn,var) #dn is the name of the country, var is the name of the variable (wage, rev, etc)
  df=DataFrame(nace4=dg[:,3],id=dg[:,4],xx1=dg[:,6],xx2=dg[:,5],xx3=dg[:,7],ctry=dn)

	mapcols(col -> replace!(col, "n.a."=> "-1"), df)
	mapcols(col -> replace!(col, ""=> "-1"), df)
	df.xx1=coalesce.(df.xx1, "-1") ; 			df.xx2=coalesce.(df.xx2, "-1") ; 			df.xx3=coalesce.(df.xx2, "-1")
	df.xx1=tryparse.(Float64,string.(df.xx1)); 	df.xx2=tryparse.(Float64,string.(df.xx2)) ;  df.xx3=tryparse.(Float64,string.(df.xx3))

	###we now create different DFs to identify at least one value of xx values
	df=df[(df.xx1 .>0) .| (df.xx2 .>0 .| (df.xx3 .>0)), :]
	df[:,:xx].=df.xx1
	[(if df.xx1[i]<=0 df.xx[i]=df.xx2[i] end) for i in eachindex(df.xx)]
	[(if df.xx[i]<=0 df.xx[i]=df.xx3[i] end) for i in eachindex(df.xx)]
	[(if df.xx[i]<=0 df.xx[i]=-1 end) for i in eachindex(df.xx)]
	df=unique(df[:,[:ctry,:id,:nace4,:xx]])
	df=df[df.xx.>0,:]

	df=unique(df)
	df=rename(df, :xx => Symbol("$var"))

	return df
  end




  			function cleanother(dg,var)
			  df=DataFrame(id=dg[:,3],xx1=dg[:,5],xx2=dg[:,4],xx3=dg[:,6])

				mapcols(col -> replace!(col, "n.a."=> "-1"), df)
				mapcols(col -> replace!(col, ""=> "-1"), df)
				mapcols(col -> replace!(col, Missing=> "-1"), df)

				df.xx1=coalesce.(df.xx1, "-1") ; 			df.xx2=coalesce.(df.xx2, "-1") ; 			df.xx3=coalesce.(df.xx2, "-1")
				df.xx1=tryparse.(Float64,string.(df.xx1)); 	df.xx2=tryparse.(Float64,string.(df.xx2)) ;  df.xx3=tryparse.(Float64,string.(df.xx3))

				###we now create different DFs to identify at least one value of xxenues
				#sort!(df,:xx1,rev=true)

				df=df[(df.xx1 .>0) .| (df.xx2 .>0) .| (df.xx2 .>0), :]
				df[:,:xx].=df.xx1
				[(if df.xx1[i]<=0 df.xx[i]=df.xx2[i] end) for i in eachindex(df.xx)]
				[(if df.xx[i]<=0 df.xx[i]=df.xx3[i] end) for i in eachindex(df.xx)]
				[(if df.xx[i]<=0 df.xx[i]=-1 end) for i in eachindex(df.xx)]
				df=unique(df[:,[:id,:xx]])
				df=df[df.xx.>0,:]

				df=unique(df)
				df=rename(df, :xx => Symbol("$var")) #sum of confidential valuesonly expressed at nace 2 digits

				return df
			  end


			  function cleanother2(dg,var) #it keeps zeros unlike cleanother - important for intangibles
  			  df=DataFrame(id=dg[:,3],xx1=dg[:,5],xx2=dg[:,4],xx3=dg[:,6])

  				mapcols(col -> replace!(col, "n.a."=> "-1"), df)
  				mapcols(col -> replace!(col, ""=> "-1"), df)
  				mapcols(col -> replace!(col, Missing=> "-1"), df)

  				df.xx1=coalesce.(df.xx1, "-1") ; 			df.xx2=coalesce.(df.xx2, "-1") ; 			df.xx3=coalesce.(df.xx2, "-1")
  				df.xx1=tryparse.(Float64,string.(df.xx1)); 	df.xx2=tryparse.(Float64,string.(df.xx2)) ;  df.xx3=tryparse.(Float64,string.(df.xx3))

  				###we now create different DFs to identify at least one value of xxenues
  				#sort!(df,:xx1,rev=true)

  				df=df[(df.xx1 .>=0) .| (df.xx2 .>=0) .| (df.xx2 .>=0), :]
  				df[:,:xx].=df.xx1
  				[(if df.xx1[i]<=0 df.xx[i]=df.xx2[i] end) for i in eachindex(df.xx)]
  				[(if df.xx[i]<=0 df.xx[i]=df.xx3[i] end) for i in eachindex(df.xx)]
				[(if ((df.xx1[i] ==0) & (df.xx2[i]==0) & (df.xx2[i]==0)) df.xx[i]=0 end) for i in eachindex(df.xx)]
				[(if df.xx[i]<0 df.xx[i]=-1 end) for i in eachindex(df.xx)]
				df=unique(df[:,[:id,:xx]])
  				df=df[df.xx.>=0,:]

  				df=unique(df)
  				df=rename(df, :xx => Symbol("$var")) #sum of confidential valuesonly expressed at nace 2 digits

  				return df
  			  end




######################### WE DEFINE COUNTRIES IN A DICTIONARY ###############################
######################### and a function to retrieve the data ###############################


##### FINAL LIST

sector=["manuf"]
	function retr(sector)
		dir="$(homedir())\\Desktop\\ORBIS\\allcountries"
			dfs=[DataFrame(CSV.File("$(dir)\\$(value)_2019_rev_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[dfs[i]=clean(dfs[i],dn[i,:cctry],Symbol("rev")) for i in eachindex(dn.ind)]
			dff=copy(dfs)


			fixs=[DataFrame(CSV.File("$(dir)\\fixed\\$(value)_2019_fixed_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[fixs[i]=cleanother(fixs[i],Symbol("fixed")) for i in eachindex(dn.ind)]
			[dff[i]=leftjoin(dfs[i],fixs[i],on=:id) for i in eachindex(dn.ind)]

			intangs=[DataFrame(CSV.File("$(dir)\\intang\\$(value)_2019_intang_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[intangs[i]=cleanother2(intangs[i],Symbol("intang")) for i in eachindex(dn.ind)]
			[dff[i]=leftjoin(dff[i],intangs[i],on=:id) for i in eachindex(dn.ind)]

			empls=[DataFrame(CSV.File("$(dir)\\empl\\$(value)_2019_empl_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[empls[i]=cleanother(empls[i],Symbol("empl")) for i in eachindex(dn.ind)]
			[dff[i]=leftjoin(dff[i],empls[i],on=:id) for i in eachindex(dn.ind)]

			rems=[DataFrame(CSV.File("$(dir)\\wage\\$(value)_2019_wage_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[rems[i]=cleanother(rems[i],Symbol("rem")) for i in eachindex(dn.ind)]
			[dff[i]=leftjoin(dff[i],rems[i],on=:id) for i in eachindex(dn.ind)]

			mats=[DataFrame(CSV.File("$(dir)\\mat\\$(value)_2019_mat_$sector.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
			[mats[i]=cleanother(mats[i],Symbol("mat")) for i in eachindex(dn.ind)]
			[dff[i]=leftjoin(dff[i],mats[i],on=:id) for i in eachindex(dn.ind)]
			return dff
		end

ctry=Dict(lowercase.([keys(ctry)...]).=> [values(ctry)...])
dn=DataFrame(nctry=[keys(ctry)...],cctry=[values(ctry)...])
dn.ind=LinearIndices(1:length(dn.cctry)) #numerical index of the country


dff=[retr(sector[1])] # aux=length(sector); push!(dff,retr(sector[2]))
dff=vcat(vcat(dff...)...)
dff.nace4.=tryparse.(Int,string.(dff.nace4))
 ####### FINAL DATASET

dfs=copy(dff)
dfs[:,:nace2]=floor.(Int,dfs.nace4/100)
dfs[:,:nace3]=floor.(Int,dfs.nace4/10)

return dfs
end


######################################################################################
####################													###############################
################ 				WE KEEP ONLY: FIRMS THAT REPORT REVENUE			 ##############################
#################						AND MANUFACTURING INDUSTRIES						#############################
######################################################################################

		  function revi(dg,crit,thresh,bb2) #to get results with revenue, it takes the cleaned the df and chooses the naces of manufacturing
		  		df=unique(dg)
		  		df=transform(DataFrames.groupby(df,:nace4),nrow => :nrfirm) #nr firms by nace and the last line modifies directlyl all
		  		nrf=size(df)[1]

		  		sort!(df,[:nace4, :rev], rev=(false,true))
		  		df=transform!(DataFrames.groupby(df, :nace4), :id => eachindex => :pos) #it could be "name" or any variable to obtain the index
		  		df=transform(DataFrames.groupby(df, :nace4),:rev => sum => :Trev4)
				df=transform(DataFrames.groupby(df, :nace2),:rev => sum => :Trev2)
				df=transform(df,:rev => sum => :Trev)
		  		df[:,:nace2]=floor.(Int,df.nace4./100)
		  		df=df[df.nace2.<33,:] #manufacturing
		  		df=df[(df.nace2.!=19) .& (df.nace2.!=12) .& (df.nace2.!=33),:] # we exclude tobacco, coke, and services
		  		df[:,:sh4].=df.rev./df.Trev4

		    	#selecting industries
		  		df3=copy(df)
		  		thr=(df3.pos .>=(df3.nrfirm.-thresh)) #.| (df.pos .>=floor.(Int,0.1 .* df.nrfirm))
		  		df3=combine(DataFrames.groupby(df3[thr,:], :nace4),:sh4 => sum => :aux1)
		  		aux2=df3[df3.aux1.<0.01,:]
		  		aux2[:,:bin].=1
		  		aux2=aux2[:,Not(:aux1)]

		  		df3=copy(df)
		  		aux3=df3[(df3.pos.==1) .& (df3.sh4.>crit) ,:]
		  		aux3[:,:bin2].=1
		  		aux3=aux3[:,[:nace4,:bin2]]

		  		aux=leftjoin(aux2,aux3,on=:nace4)
		  		aux.bin2=coalesce.(aux.bin2, 0)

		  		df4=leftjoin(df,aux,on=:nace4) #to merge the result with the df
		  		df4.bin=coalesce.(df4.bin, 0)
		  		df4.bin2=coalesce.(df4.bin2, 0)

				if bb2==1 dg=dg[(dg.bin2.==1),:] end

		  		return df4
		  	end
