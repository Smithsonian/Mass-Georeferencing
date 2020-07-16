#!/usr/bin/env python3
#
# Extract data fields from the dataset XML files from a 
#  GBIF DarwinCore download.
#

import os, xmltodict, codecs, re

summaryfile = codecs.open("gbifdatasets.csv", 'w', 'utf-8')
summaryfile.truncate()

#Write header, pipes as separators
summaryfile.write('"dataset_id"|"title"|"organizationName"|"rights"|"doi"|"date"|"citation"|"license"|"pubDate"\n')

for filename in os.listdir(os.getcwd()):
	if filename[-4:] != '.xml':
		continue

	#Get dataset id from filename
	dataset_id = filename[:-4]
	print(dataset_id)
	with codecs.open(filename, 'r', 'utf-8') as fd:
	    doc = xmltodict.parse(fd.read())

	title = doc['eml:eml']['dataset']['title']
	title = title.replace('"', '\'')
	print(title)

	#Try to find DOI
	try:
		try:
			doi = doc['eml:eml']['dataset']['alternateIdentifier'][0]['#text']
		except:
			try:
				doi = doc['eml:eml']['dataset']['alternateIdentifier'][0]
			except:
				doi = doc['eml:eml']['dataset']['alternateIdentifier']
	except:
		doi = ""

	#Get organization name
	try:
		organizationName = doc['eml:eml']['dataset']['creator']['organizationName']
		organizationName = organizationName.replace('"', '\'')
	except:
		organizationName = ""

	try:
		rights = doc['eml:eml']['dataset']['intellectualRights']['para']
		rights = re.sub('<[^>]*>', '', rights)
	except:
		rights = ""

	#Get timestamp of dataset
	try:
		dateStamp = doc['eml:eml']['additionalMetadata']['metadata']['gbif']['dateStamp']
	except:
		dateStamp = ""

	if doi[:4] == "doi:":
		doi = doi[4:]
	else:
		doi = ""

	date = doc['eml:eml']['additionalMetadata']['metadata']['gbif']['dateStamp']

	#Get citation
	try:
		citation = doc['eml:eml']['additionalMetadata']['metadata']['gbif']['citation']['#text']
	except:
		try:
			citation = doc['eml:eml']['additionalMetadata']['metadata']['gbif']['citation']
		except:
			citation = ""

	citation = citation.replace('"', '\'')
	citation = citation.replace('\n', '')
	
	#License info
	try:
		license = doc['eml:eml']['dataset']['intellectualRights']['para']['ulink']['citetitle']
	except:
		license = ""
	
	try:
		pubDate = doc['eml:eml']['dataset']['pubDate']
	except:
		pubDate = ""

	summaryfile.write('"')
	summaryfile.write(dataset_id)
	summaryfile.write('"|"')
	summaryfile.write(title.replace('"', '\''))
	summaryfile.write('"|"')
	summaryfile.write(organizationName.replace('"', '\''))
	summaryfile.write('"|"')
	summaryfile.write(rights.replace('"', '\''))
	summaryfile.write('"|"')
	summaryfile.write(doi)
	summaryfile.write('"|')
	summaryfile.write(date)
	summaryfile.write('|"')
	summaryfile.write(citation.replace('"', '\''))
	summaryfile.write('"|"')
	summaryfile.write(license.replace('"', '\''))	
	summaryfile.write('"|"')
	summaryfile.write(pubDate.replace('"', '\''))	
	summaryfile.write('"\n')

summaryfile.close()
