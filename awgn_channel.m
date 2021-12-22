function received = awgn_channel(modulated, snr)
% INPUT: 
%   modulated: transmitted modulated signal
%   snr: value of the signal to noise ratio 
% OUTPUT: 
%   received: noise added modulated signal that appears at the receiver

received = awgn(modulated, snr, 'measured');

t=(1 : 1 :length(modulated));
subplot(1,2,1);
plot(t,(modulated)','b');
legend('Original Signal');
ylim([-5 5]);
xlabel('Sample');
ylabel('Amplitude');
subplot(1,2,2);
plot(t,(received)','r');
legend('Signal with AWGN');
ylim([-5 5]);
xlabel('Sample');
ylabel('Amplitude');

end