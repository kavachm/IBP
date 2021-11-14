clc
clearvars
close all
img_lr=imread('D:\aviris\subsetted data scaled prisma\band15.tif'); 
ratio=2;
sigma = 2.1; 
iternum = 100; 
breport = true;
tic;
IntAlg ='bicubic';
img_lri= imresize(img_lr,ratio,IntAlg);
[h_hr,w_hr] = size(img_lri);
[h_lr] = size(img_lr,1);
criterion_stop = h_hr*w_hr*0.9999;
img_hr=img_lri;
for i=1:iternum
img_hr1 = im2double(img_hr);
[h, w, d] = size(img_hr1);
htrim = h-mod(h,ratio);
wtrim = w-mod(w,ratio);
imtrim = img_hr1(1:htrim,1:wtrim,1:d);
h_lr1 = htrim/ratio;
w_lr1 = wtrim/ratio;
    if mod(ratio,2) == 1
        kernelsize = ceil(sigma*3)*2+1;
        kernel = fspecial('gaussian',kernelsize,sigma);
        if d == 1
            blurimg = imfilter(imtrim,kernel,'replicate');
        end
        img_lr1 = imresize(blurimg,1/ratio,'nearest');
    elseif mod(ratio,2) == 0
        sampleshift = ratio/2;
        kernelsize = ceil(sigma*3)*2+2;
        kernel = fspecial('gaussian',kernelsize,sigma); 
        img_blur = imfilter(imtrim,kernel,'replicate');
        img_lr1 = zeros(h_lr1,w_lr1,d);
        for didx = 1:d
            for rl=1:h_lr1
                r_hr_sample = (rl-1)*ratio+sampleshift;
                for cl = 1:w_lr1
                    c_hr_sample = (cl-1)*ratio+sampleshift;
                    img_lr1(rl,cl,didx) = img_blur(r_hr_sample,c_hr_sample,didx);
                end
            end
        end
    end
diff_lr = img_lr - img_lr1;
RMSE_diff_lr = sqrt(mean2(diff_lr.^2));
[h1, w1] = size(diff_lr);
h_hr1 = h1*ratio;
w_hr1 = w1*ratio;
map_upsampled = zeros(h_hr1,w_hr1);
    if mod(ratio,2) == 1
       half_ratio = (ratio-1)/2;
       for rl = 1:h1
           rh = (rl-1) * ratio + half_ratio + 1;
           for cl = 1:w1
               ch = (cl-1) * ratio + half_ratio + 1;
               map_upsampled(rh,ch) = diff_lr(rl,cl);
           end
       end
       kernelsize1 = ceil(sigma * 3)*2+1;
       kernel1 = fspecial('gaussian',kernelsize1,sigma);
       diff_hr = imfilter(map_upsampled,kernel1,'replicate');
    else
        kernelsize1=ceil(sigma * 3)*2+2;
        kernel1 = fspecial('gaussian',kernelsize1,sigma);
        half_ratio = ratio/2;
        for rl = 1:h1
            rh = (rl-1) * ratio + half_ratio +1;
            for cl = 1:w1
                ch = (cl-1) * ratio + half_ratio + 1;
                map_upsampled(rh,ch) = diff_lr(rl,cl);
            end
        end
        diff_hr = imfilter(map_upsampled, kernel1,'replicate');
    end
img_hr2=img_hr1+diff_hr;
[h2, w2, d2] = size(img_hr2);
htrim1 = h2-mod(h2,ratio);
wtrim1 = w2-mod(w2,ratio);
imtrim1 = img_hr2(1:htrim1,1:wtrim1,1:d2);
h_lr2 = htrim1/ratio;
w_lr2 = wtrim1/ratio;
    if mod(ratio,2) == 1
        kernelsize2 = ceil(sigma*3)*2+1;
        kernel2 = fspecial('gaussian',kernelsize2,sigma);
        if d2 == 1
            blurimg1 = imfilter(imtrim,kernel2,'replicate');
        end
        img_lr2 = imresize(blurimg1,1/ratio,'nearest');
    elseif mod(ratio,2) == 0
        sampleshift1 = ratio/2;
        kernelsize2 = ceil(sigma*3)*2+2;
        kernel2 = fspecial('gaussian',kernelsize2,sigma); 
        img_blur2 = imfilter(imtrim,kernel2,'replicate');
        img_lr2 = zeros(h_lr2,w_lr2,d2);
        for didx1 = 1:d2
            for r2=1:h_lr2
                r_hr_sample1 = (r2-1)*ratio+sampleshift1;
                for c2 = 1:w_lr2
                    c_hr_sample1 = (c2-1)*ratio+sampleshift1;
                    img_lr2(r2,c2,didx1) = img_blur(r_hr_sample1,c_hr_sample1,didx1);
                end
            end
        end
    end
diff_lr_new = img_lr - img_lr2;
RMSE_diff_lr_afteronebackprojection = sqrt(mean2(diff_lr_new.^2));
        if breport
            fprintf('backproject iteration=%d, RMSE_before=%0.6f, RMSE_after=%0.6f\n', ...
            i,RMSE_diff_lr,RMSE_diff_lr_afteronebackprojection);        
        end
        if nnz(abs(diff_hr)<(1/256)) > criterion_stop
            disp('Most hr pixels stills');
            break;
        end
end
img_bp=img_hr2;
img_sr1=img_bp;
TIME=toc;
img_sr=single(img_sr1);
t1=Tiff('D:\EO1H1490442002308110PZ_1T\outputs\New folder (4) 0.1-2 prisma ibp\band15_2-1_2.tif','w');
tagstruct2.ImageLength = size(img_sr,1);
tagstruct2.ImageWidth = size(img_sr,2);
tagstruct2.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct2.BitsPerSample = 32;
tagstruct2.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct2.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct2.Software = 'MATLAB';
t1.setTag(tagstruct2)
t1.write(img_sr);
t1.close();
figure;imagesc(imread('D:\EO1H1490442002308110PZ_1T\outputs\New folder (4) 0.1-2 prisma ibp\band15_2-1_2.tif'));

