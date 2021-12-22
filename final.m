clc;
clear;
close all; 
start = tic;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "System Properties"                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modulation_name = 'BASK'; 
samples_per_bit = 40; 
Rb = 1000; 
amp = [1 0];
freq = 1000;                         
snr = 10; 
Generator = [1 1 0; 1 0 1]; 
shift = 1; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                      "Reading Text Data File"                       %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('Enter 0 for one-to-one text message transfer ');
disp('Enter 1 for text file transfer ');
disp('Enter 2 for image file transfer');
a=input('Enter your choice : ');
while(~(a==0 | a==1 | a==2))
    a=input('Enter your choice : ');
end
if(a==0)
    text=input('Enter your message : ','s');
end 
if(a==1)
    fprintf('Reading data: '); 
    [textfilename,textfilepath] = uigetfile('*.txt');
    textfilecontent = fopen([textfilepath textfilename],'r');
    text = fread(textfilecontent, '*char')';
    fclose(textfilecontent);
end 
if(a==2)
    [imagefilename,imagefilepath] = uigetfile('*.bmp;*.tif;*.jpg;*.pgm','Pick an M-file');
    img = imread(imagefilename);
    [ row col p ] =size(img);
    red=img(:,:,1);
    redt=red';
    redsized=redt(:)';
    green=img(:,:,2);
    greent=green';
    greensized=greent(:)';
    blue=img(:,:,3);
    bluet=blue';
    bluesized=bluet(:)';
    text=cat(2,redsized,greensized,bluesized);
end
toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "Source Statistics"                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Source statistics: '); 
tic
[unique_symbol, probability] = source_statistics(text); 
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "Huffman Encoding"                          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Huffman encoding: '); 
tic 
code_word = huffman_encoding(probability); 
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "Stream Generator"                          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Stream generator: '); 
bit_stream = stream_generator(unique_symbol, code_word, text);
input = bit_stream;
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                          "Channel Coding"                           %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Channel coding: '); 
channel_coded = convolutional_coding(bit_stream, Generator);
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                            "Modulation"                             %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Modulation: ');
modulated = modulation(modulation_name, channel_coded, Rb, samples_per_bit, amp, freq); 
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                              "Channel"                              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Channel: ');
received = awgn_channel(modulated, snr); 
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                           "Demodulation"                            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Demodulation: ');
bit_stream = demodulation(modulation_name, received, Rb, samples_per_bit, amp, freq);
toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "Channel Decoding"                          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Channel decoding: ');
bit_stream = viterbi_decoder(bit_stream, Generator, shift); 
output = bit_stream; 
toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                         "Huffman Decoding"                          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('Huffman decoding: ');
decoded_msg = huffman_decoding(unique_symbol, code_word, bit_stream); 
toc 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                    "Writting the Received Data"                     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
if(a==0)
    msgrecID = fopen('ReceivedData/received_direct_messages.txt','a');
    decoded_msg=[decoded_msg newline newline];
    fwrite(msgrecID,decoded_msg);
    fclose(msgrecID);
end  
if(a==1)
    textfilerecID = fopen('ReceivedData/received_text_files/'+""+(textfilename),'w');
    fwrite(textfilerecID,decoded_msg);
    fclose(textfilerecID);
end
if(a==2)
    decoded_msg=uint8(decoded_msg);
    cr=decoded_msg(:,1:(row*col));
    cg=decoded_msg(:,((row*col)+1):(2*row*col));
    cb=decoded_msg(:,((2*row*col)+1):(3*row*col));
    matrix_r=reshape(cr,col,row)';
    matrix_g=reshape(cg,col,row)';
    matrix_b=reshape(cb,col,row)';
    finalimg=cat(3,matrix_r,matrix_g,matrix_b);
    imwrite(finalimg,'ReceivedData/received_images/'+""+(imagefilename));
end
toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                     "Time & Error Calculation"                      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Total execution time: ');
toc(start); 

Error = sum(abs(input - output)); 
disp(['Total Bit Error: ' num2str(Error)]); 