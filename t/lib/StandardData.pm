package StandardData;
# ABSTRACT: Data from standard

use strict;
use warnings;
use List::AllUtils qw(first);

sub lis02a2_standard_data {
	my @data = (
		#{
			## Note 1 This sample is not recommended for implementation.
			#id => 'fig3',
			#desc => 'Figure 3. Minimal Implementation (No Patient ID or Specimen ID)',
			#text => <<~'EOF',
				#EOF
		#},
		{
			id => 'fig4',
			desc => 'Figure 4. No Patient ID; Specimen ID and Multiple Results Shown',
			text => <<~'EOF',
	H|\^&
	  P|1
	    O|1|927529||^^^A1\^^^A2
	      R|1|^^^A1|0.295||||||||19890327132247
	      R|2|^^^A2|0.312||||||||19890327132248
	  P|2|
	    O|1|927533||^^^A3\^^^A4
	      R|1|^^^A3|1.121||||||||19890327132422
	      R|2|^^^A4|1.097||||||||19890317132422
	L|1
	EOF
		},
		{
			id => 'fig5',
			desc => 'Figure 5. Request from Analyzer for Test Selections on Specimens 032989325-032989327',
			text => <<~'EOF',
H|\^&||PSWD|Harper Labs|2937 Southwestern Avenue^Buffalo^NY^73205||319 412-9722||||P|1394-97|19890314
  Q|1|^032989325|^032989327|ALL||||||||O
L|1|N
EOF
		},
		{
			id => 'fig6',
			desc => 'Figure 6. Response from Information System for Previous Request',
			text => <<~'EOF',
H|\^&||PSWD|Harper Labs|2937 Southwestern Avenue^Buffalo^NY^73205||319 412-9722||||P|1394-97|19890314
  P|1|2734|123|306-87-4587|BLAKE^LINDSEY^ANN^MISS
    O|1|032989325||^^^BUN|R
    O|2|032989325||^^^ISE|R
    O|3|032989325||^^^HDL\^^^GLU|R
  P|2|2462|158|287-17-2791|POHL^ALLEN^M.
    O|1|032989326||^^^LIVER\^^^GLU|S
  P|3|1583|250|151-37-6926|SIMPSON^ALBERT^^MR
    O|1|032989327||^^^CHEM12\^^^LIVER|R
L|1|F
EOF
		},
		{
			id => 'fig7',
			desc => 'Figure 7. Results from Given Ordered Test Selections Shown in Various Formats',
			text => <<~'EOF'=~ s/\Q<CR> ###\E.*$//gmr,
H|\^&||PSWD|Harper Labs|2937 Southwestern Avenue^Buffalo^NY^73205||319 412-9722||||P|1394-97|19890314
  P|1|2734|123|306-87-4587|BLAKE^LINDSEY^ANN^MISS
  C|1|L|Notify IDC if tests positive|G
    O|1|032989325||^^^BUN|R
      R|1|^^^BUN|8.71
      C|1|I|TGP^Test Growth Positive|P
      C|2|I|colony count >10,000|P
    O|2|032989325||^^^ISE|R
      R|1|^^^ISE^NA|139|mEq/L
      R|2|^^^ISE^K|4.2|mEq/L
      R|3|^^^ISE^CL|111|mEq/L
    O|3|032989325||^^^HDL|R
      R|1|^^^HDL|70.29
    O|4|032989325||^^^GLU|R
      R|1|^^^GLU|92.98
      C|1|I|Reading is Suspect|I
  P|2|2462|158|287-17-2791|POHL^ALLEN^M.
    O|1|032989326||^^^LIVER|S
      R|1|^^^LIVER^AST|29
      R|2|^^^LIVER^ALT|50
      R|3|^^^LIVER^TBILI|7.9
      R|4|^^^LIVER^GGT|29
    O|2|032989326||^^^GLU|S
      R|1|^^^GLU|91.5
  P|3|1583|250|151-37-6926|SIMPSON^ALBERT^^MR
    O|1|032989327||LIVER|R
      R|1|^^^AST|28<CR> ###(Test ID field Implicitly Relates to LIVER order)
      R|2|^^^ALT|49
      R|3|^^^TBILI|7.3
      R|4|^^^GGT|27
    O|2|032989327||CHEM12|R
      R|1|^^^CHEM12^ALB-G|28<CR> ###(Test ID field Explicitly Relates to CHEM12 order)
      R|2|^^^CHEM12^BUN|49
      R|3|^^^CHEM12^CA|7.3
      R|4|^^^CHEM12^CHOL|27
      R|5|^^^CHEM12^CREAT|4.2
      R|6|^^^CHEM12^PHOS|12
      R|7|^^^CHEM12^GLUHK|9.7
      R|8|^^^CHEM12^NA|138.7
      R|9|^^^CHEM12^K|111.3
      R|10|^^^CHEM12^CL|6.7
      R|11|^^^CHEM12^UA|7.3
      R|12|^^^CHEM12^TP|9.2
L|1
EOF
		},
		{
			id => 'fig8',
			desc => 'Figure 8. Request from Information System to Instrument for Previously Run Results',
			text => <<~'EOF',
H|\^&||PSWD|Harper Labs|2937 Southwestern Avenue^Buffalo^NY^73205||319 412-9722||||P|1394-97|19890314
  Q|1|032989326||ALL
L|1
EOF
		},
		{
			id => 'fig9',
			desc => 'Figure 9. Reply to Result Request',
			text => <<~'EOF',
H|\^&||PSWD|Harper Labs|2937 Southwestern Avenue^Buffalo^NY^73205||319 412-9722||||P|1394-97|19890314
  P|1|2462|158|287-17-2791|POHL^ALLEN^M.
    O|1|032989326||^^^LIVER|S
      R|1|^^^AST|29
      R|2|^^^ALT|50
      R|3|^^^TBILI|7.9
      R|4|^^^GGT|29
    O|2|032989326||^^^GLU|S
      R|1|^^^GLU|91.5
L|1|F
EOF
		},
		{
			id => 'fig10',
			desc => 'Figure 10. Microbiology Order and Result-Download of Demographics and Order',
			text => <<~'EOF',
H|\^&||Password1|Micro1|||||LSI1||P|1394-94|19890501074500
  P|1||52483291||Smith^John|Samuels|19600401|M|W|4526 C Street^Fresno^CA^92304||(402)782-3424x242|542^Dr.Brown|||72^in.|175^lb.||Penicillin||||19890428|IP|Ward1|||C|M|WSP||ER|PC^Prompt Care
    O|1|5762^01||^^^BC^BloodCulture^POSCOMBO|R|198905011530|198905020700|||456^Farnsworth|N|||198905021130|BL^Blood|123^Dr.Wirth||||||||Instrument#1|||ER|N
      R|1|^^^Org#|51^Strep Species|||N
      R|2|^^^Bio|BH+^Beta Hemolytic|||N
L|1
EOF
		},
		{
			id => 'fig11',
			desc => 'Figure 11. Microbiology Order and Result-Upload of Finalized Results',
			text => <<~'EOF' =~ s/ (?<indent>\s*) \Q...\E \n \k<indent> \QR|90|\E /$+{indent}R|14|/mxr,
H|\^&||Password1|Micro1|||||LSI1||P|1394-94|19890501074500
  P|1||52483291
    O|1|5762^01||^^^BC^^POSCOMBO|||||||||||BL||||||||||F
      R|1|^^^ORG#|103^Group D Entero
      R|2|^^^AM^MIC|>16
      R|3|^^^AM^INTERP1|++
      R|4|^^^AM^DOSAGE1|PO 250-500 mg Q6h
      R|5|^^^AM^DOSAGE1^COSTCODE|$25
      R|6|^^^AM^INTERP2|+++
      R|7|^^^AM^DOSAGE2|IV 1.0-2.0 gm Q4h
      R|8|^^^P^MIC|<0.25
      R|9|^^^P^INTERP1|++
      R|10|^^^P^DOSAGE1|PO 250-500 mg Q6h
      R|11|^^^P^DOSAGE1^COSTCODE|$25
      R|12|^^^P^INTERP2|+++
      R|13|^^^P^DOSAGE2|IM 0.9-1.2 MIL U Q6-12h
      ...
      R|90|^^^BIOTYPE|102-34021
L|1
EOF
		},
	);

	\@data;
}

sub lis02a2_standard_data_text_to_message_text {
	my ($class, $data_text) = @_;
	my $message_text = $data_text
		=~ s/^(?<indent>\s*)//mgr
		=~ s/\n/\r/gsr;  # record separator
	return $message_text;
}

sub get_message_text_by_id {
	my ($class, $id) = @_;
	my $text = $class->lis02a2_standard_data_text_to_message_text(
		( first { $_->{id} eq $id } @{ $class->lis02a2_standard_data } )
			->{text}
	);
}

1;
