#!/usr/bin/python
import sys

######################## CLASSES ##################################################
class SPCelm:
	def __init__(self,name,elm_dic):
		self.name    = name
		self.elm_dic = elm_dic
class CONTROL:
	def __init__(self,fuel,oxid,prod):
		self.fuel = fuel
		self.oxid = oxid
		self.prod = prod

		arr = []
		arr.extend(self.fuel.keys())
		arr.extend(self.oxid.keys())
		arr.extend(self.prod.keys())
		self.species = list(set(arr))
	def set_species(self,dic_species):
		self.dic_species = dic_species
		arr =[]
		for var in self.dic_species.values(): arr.extend(var.keys())
		self.elements = list(set(arr))
	def check_consistency(self):
		reac_sum={}
		for key in self.elements:reac_sum[key]=0
		for spc,amount in self.fuel.items():
			for key,var in self.dic_species[spc].items():
				reac_sum[key]+=var*amount
		for spc,amount in self.oxid.items():
			for key,var in self.dic_species[spc].items():
				reac_sum[key]+=var*amount

		prod_sum={}
		for key in self.elements:prod_sum[key]=0
		for spc,amount in self.prod.items():
			for key,var in self.dic_species[spc].items():
				prod_sum[key]+=var*amount

		for key in self.elements:
			if abs(2*(reac_sum[key]-prod_sum[key])/(reac_sum[key]+prod_sum[key]))>0.01:
			 	print "Consistency check failed!"
			 	print "Please check the compositions of reactants and products again."
			 	sys.exit(1)
		print "Consistency check succeeded!"

	
######################## FUNCTIONS ################################################
def read_thermo():
	fp = open("thermo.inp")
	while True:
		if fp.readline()[:1] != '!': break
	fp.readline()
	
	SPClist = []
	while True:
		name = fp.readline()[:18].strip()
		if name[:3] == "END": break
		line = fp.readline()
		Nsctn     = int(line[:2])
		phase     = int(line[51:52])
		elem_line = line[10:50]
		elm_dic={}
		for i in range(5):
			elm       = elem_line[ :2]
			amount    = elem_line[2:8].strip()
			elem_line = elem_line[8:]
			if(elm == '  '):break
			elm_dic[elm]=float(amount)
		for i in range(Nsctn*3):fp.readline()
		if phase ==0: SPClist.append(SPCelm(name,elm_dic))
	fp.close()
	return SPClist

def read_control_chem():
	fp = open("control_chem.inp")

	for i in range(4): fp.readline()
	fuel = {}
	while True:
		line = fp.readline().strip()
		if(line == 'end'):break
		[key,val] = line.split()
		fuel[key] = float(val)

	for i in range(3): fp.readline()
	oxid = {}
	while True:
		line = fp.readline().strip()
		if(line == 'end'):break
		[key,val] = line.split()
		oxid[key] = float(val)

	fp.readline()
	prod = {}
	while True:
		line = fp.readline().strip()
		if(line == 'end'):break
		[key,val] = line.split()
		prod[key] = float(val)

	fp.close()
	return CONTROL(fuel,oxid,prod)

def fetch_elm_info(SPClist,control):
	controlSPC = control.species
	dic = {}
	for SPCmono in SPClist:
		for species in controlSPC:
			if(SPCmono.name == species):
				dic[species] = SPCmono.elm_dic
				break
	control.set_species(dic)
	return control

def trimSPC(SPClist,elements):
	trimed = []
	for SPC in SPClist:
		flag = True
		for elm in SPC.elm_dic.keys():
			if not elm in elements : flag = False
		if flag: trimed.append(SPC.name)
	return trimed

def out_arr(filename,arr):
	fp = open(filename,"w")
	for var in arr:fp.write(var+"\n")
	fp.close()
	return len(arr)

######################## MAIN ################################################
def preCEA(var):
	SPClist = read_thermo()
	control = read_control_chem()
	control = fetch_elm_info(SPClist,control)
	if var ==0:
		control.check_consistency()
		trimedSPC = control.species
	else:
		trimedSPC = trimSPC(SPClist,control.elements)
	numelm = out_arr("elements_to_use.inp",control.elements)
	numspc = out_arr("species_to_use.inp", trimedSPC)
	return [numelm,numspc]

if __name__ == "__main__":
	var = 0 #0:flamesheet, 1: CEA
	print preCEA(var)
