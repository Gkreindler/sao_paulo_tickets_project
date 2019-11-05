/*

This do file takes the cluster notes excel spreadsheet and generates some simple summary statistics from the data.

*/

// clear STATA
clear

// file path
global s "/Users/san/Google Drive/Academics/Harvard RA/Sao Paolo Speed Cameras/sao_paulo_tickets_project/"

// change working directory
cd "$s"

// imports the excel file, uses first row as variable names
import excel "cluster_notes.xlsx", first

// drops empty rows
drop if location == ""

