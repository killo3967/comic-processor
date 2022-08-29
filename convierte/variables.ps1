[xml]$Global:comicinfo_xml = @(
'<?xml version="1.0"?>',
'<ComicInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema">',
    "<Title>$cv_title</Title>"                          
    "<Series>$cv_series</Series>",                      
    "<Number>$cv_number</Number>",                      
    "<Count>$cv_volume</Count>"                         
    "<Volume>$cv_volume</Volume>",                      
    "<Storyarc>$cv_story_arc</Storyarc>",                           
    "<Summary>$cv_summary</Summary>",                   
    "<Notes>$cv_notes</Notes>",                         
    "<Year>$cv_year</Year>",
    "<Month>$cv_month</Month>",
    "<Day>$cv_day</Day>",
    "<Writer>$cv_writer</Writer>",
    "<Penciller>$cv_penciller</Penciller>",
    "<Inker>$cv_inker</Inker>",
    "<Colorist>$cv_colorist</Colorist>",
    "<Letterer>$cv_letterer</Letterer>",
    "<CoverArtist>$cv_coverartist</CoverArtist>",
    "<Editor>$cv_editor</Editor>",
    "<Publisher>$cv_publisher</Publisher>",
    "<Web>$cv_web</Web>",                               
    "<PageCount>$cv_pagecount</PageCount>",
    "<Characters>$cv_characters</Characters>",
    "<Teams>$cv_teams</Teams>",
    "<Locations>$cv_locations</Locations>",
#    "<Pages>",
#    "   <Page Type=$cv_pagetype ImageHeight=$cv_ImageHeight ImageWidth=$cv_ImageWidth Image=$cv_image/>",
#    "</Pages>",
    "<ISBN>$cv_isbn</ISBN>",
    "<comicvine_issue_id>$cv_comicvine_issue_id</comicvine_issue_id>",
    "<comicvine_volume_id>$cv_comicvine_volume_id</comicvine_volume_id>"
"</ComicInfo>"
)

$Global:cv_title
$Global:cv_series
$Global:cv_number
$Global:cv_count
$Global:cv_volume
$Global:cv_story_arc
$Global:cv_summary
$Global:cv_notes
$Global:cv_year
$Global:cv_month
$Global:cv_day
$Global:cv_writer
$Global:cv_penciller
$Global:cv_inker
$Global:cv_colorist
$Global:cv_letterer
$Global:cv_coverartist
$Global:cv_editor
$Global:cv_publisher
$Global:cv_web
$Global:cv_pagecount
$Global:cv_characters
$Global:cv_teams
$Global:cv_locations
$Global:cv_isbn
$Global:cv_comicvine_issue_id
$Global:cv_comicvine_volume_id
