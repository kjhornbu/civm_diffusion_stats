function [graphs, ase_Regional, ase_Global, ...
    mds_Global, mds_Regional, mds_Regional_bilat, ...
    Dist_Global, Dist_Regional, Dist_Regional_bilat, ...
    main_embedding_median_eigen,eigen_Global, eigen_Regional, eigen_Regional_bilat] = ...
    graphs_to_omnibus_embedding(df, graphs, do_binarize, do_mean_subtract, do_ptr, do_augment, scale)

n_graphs=size(df,1);
n_vertices=size(graphs,2);
% randomize order to validate no-order dependence of ase output, it
% validated, so no need to keep it on.(data was 100% identical)
randomize_vertex_order=false;
%% General modifications to Graphs
if do_binarize==1 %binarization so if above or below a certain value you can assign as zero!
    disp('Binarized Graphs...');
    graphs(graphs>0)=1;
    %graphs(graphs<150)=0;
    %graphs(graphs<1917)=0;
end

if do_mean_subtract==1
    disp('Mean Subtracted...'); %removing Central mean
    mean_connectome=squeeze(mean(graphs,1));
    for n=1:size(graphs,1)
        graphs(n,:,:)=squeeze(graphs(n,:,:))-mean_connectome;
    end
end

if do_ptr==1
    disp('PTR Completed...'); %pass to rank (as in making the entries fo the vectors have weights equal to the amount of connectivity each has
    for n=1:size(graphs,1)
        graphs(n,:,:)=ptr(squeeze(graphs(n,:,:)));
    end
end

if do_augment==1
    disp('Augmented the Diagonal...'); %making a response go into the diagonal of the graph... not exactly the most useful. It is the average response of the vector
    for n=1:size(graphs,1)
        graphs(n,:,:)=diag_aug(squeeze(graphs(n,:,:)));
    end
end

if randomize_vertex_order
    % randomize order (save order for later so we can reverse it)
    graph_order=randperm(n_vertices);
    graphs=graphs(:,graph_order,graph_order);
    % return order back to input
    %graphs(:,graph_order,graph_order)=graphs;
end

if scale==1
    % do whatever desired brain volume scaling
    for n=1:n_graphs
        A(n,:,:)=df.scale(n)*squeeze(graphs(n,:,:));
    end
else
    % or not
    A=graphs;
end
%% 
%Looping Form
% for n=1:n_graphs
%     for m=1:n_graphs
%         omni((n-1)*n_vertices+1:n*n_vertices,(m-1)*n_vertices+1:m*n_vertices)=(A(n,:,:)+A(m,:,:))/2;
%     end
% end

%NonLooping Form (faster)
B=permute(A,[2 3 1]); %switch order of graphs
C=reshape(B, n_vertices,n_vertices*n_graphs);%unwrap the dimension of number of graphs into the dataset (column way) [1 2 3 4]

T=repmat(C,n_graphs,1); %Force Repeat along rows [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4]

D=permute(B,[2 3 1]); %switch order of graphs
E=reshape(D, n_vertices*n_graphs,n_vertices); %unwrap the dimension of number of graphs into the dataset (row way) [1; 2; 3; 4]

T2=repmat(E,1,n_graphs); %Force repeat along rows [1 1 1 1; 2 2 2 2; 3 3 3 3; 4 4 4 4]

omni=(T+T2)/2; %[1 1.5 2 2.5; 1.5 2 2.5 3; 2 2.5 3 3.5; 2.5 3 3.5 4]

%% Likelyhood analysis

% Need scree analaysis to pick number of points to keep. You can do eign
% values of full omni or indiivdual A matrices. Do not reshape the matrix,
% the data you need is on elb[2]. embed A*A^T (then do the sqrt of eigen
% analysis)
%Use individual A matrices
% getElbows will return UP TO the number of significants asked for. if
% there aren't that many elbows, then it will return only the significant
% elbows. This crashes the code when some rows have fewer elbows than the
% rest.
% test with a large elbow_grab, and empirically decide based on that result

% we select a number of elbow_grab which is the maximal number of elebows
% to grab if we can't grab a certain number we go to the next maximal
% number
elbow_grab=12;
for n=1:n_graphs
    [V(:,n), ~] = sort(eig(sqrt(squeeze(A(n,:,:))*ctranspose(squeeze(A(n,:,:))))),'descend'); 
    x = length(getElbows(squeeze(V(:,n)),elbow_grab));
    if x<elbow_grab
        elbow_grab = x;
    end
end
%Then we find the estimated elbows
for n=1:n_graphs
    [q(n,:)] = getElbows(squeeze(V(:,n)),elbow_grab);
end

% elbow_grab=12;
% for n=1:n_graphs
%     [V(:,n), ~] = sort(eig(sqrt(squeeze(A(n,:,:))*ctranspose(squeeze(A(n,:,:))))),'descend'); 
%     x = length(getElbows(squeeze(V(:,n)),elbow_grab));
%     if x<elbow_grab
%         elbow_grab = x;
%     end
% end
% 
% %elbow_grab=6;
% for n=1:n_graphs
%     %This is a quick and dirty eigen analysis to determine what number of variables to keep (it is the norm of the response of each individual graph)
%     %[V(:,n), ~] = sort(eig(sqrt(squeeze(A(n,:,:))*ctranspose(squeeze(A(n,:,:))))),'descend'); % A is a single graph (with or without scaling applied)
%     %V(V(:,n)<0,n)=0;
%     %[q(n,:)] = getElbows(abs(squeeze(V(:,n))),3);
%     %[q(n,:)] = getElbows(squeeze(V(:,n)),elbow_grab);
%     [q(n,:)] = getElbows(squeeze(V(:,n)),elbow_grab);
%     %inputs the data you wish to find the number of terms to keep on (a rank ordered list of eigenvalues),
%     %and a conservative # of the maximum number of those terms you want to pull
% end

%Selecting elbow for analysis
% elb=round(mean(q(:,2))); %normally pick second elbow, but want average second elbow response %elb =3; %they used because they typically were finding elbows with 3 variables and just hard coded.
% James moved this to the the first elbow with a median greater or equal to 6.
% The rational is that it appeared the first three entries were tied to
% spatial coordinates, and it seems "cool" to have at least 3 non-spatial
% entries.
% no... elb =3 is the find the first 3 elbows of the graph. those are
% typically 1, something in the 3-6 range, and something larger but not
% more than like 30. The numbers I'm giving are the number of possible
% coeffs. 

V(V<0)=0;
total_V=sum(V,1);

% Pick elbow as first possible "second elbow" candidate (typically the second or third) that has a median value >=0.8 (across all specimen) of
% the signal represented in the eigenterms (median at a given position)

elb_med=round(median(q,1));
elb_found=0;
n=1;
while and(n <= numel(elb_med), elb_found ~=1)
    value_Median=median(sum((V(1:elb_med(n),:)./total_V),1));
    if and(value_Median>=0.8, n>1)
        elb=elb_med(n);
        elb_found=1;
        main_embedding_median_eigen=median(V(1:elb_med(n),:)./total_V,2);
    end
    n=n+1;
end

% elb_med=round(median(q,1));
% idx=find(elb_med>=6); % 6... Not really off of anything? 
% elb=elb_med(idx(1));

% svds requires doubles as input matrices, connectomes are often uint64.
omni=double(omni);
% per svds documentation:
% U = left singular vectors.
% D = diagonal matrix of singualr values.
% show some diagnostic info while we run?
% [U,D,~]=svds(omni,elb, 'Display', 1);
%{
% testing code to prove stability of the calculated parameters. 
% This grants th e confidence that we can always have a lot of parameters
% without compromising accuracy, even if we struggle to choose a good test
% for them all. 
[U10,D10,~]=svds(omni,10);
[U6,D6,~]=svds(omni,6);
[U3,D3,~]=svds(omni,3);
a10=U10*sqrt(D10);
a6=U6*sqrt(D6);
a3=U3*sqrt(D3);

t_i=1
[U3(1:6,t_i)';U6(1:6,t_i)';U10(1:6,t_i)']
[D3(t_i,t_i),D6(t_i,t_i),D10(t_i,t_i)]
[a3(t_i),a6(t_i),a10(t_i)]

% convert D3 6 an d10 to vectors by extracting along the diagonal.
D3v=D3(diag(ones(1,3,'logical')));
D6v=D6(diag(ones(1,6,'logical')));
D10v=D10(diag(ones(1,10,'logical')));

% Out to 14 signficant figures, d3== d6, and the same istrue for d6 and d10
errs=nnz(round(D3v./D6v(1:3),14,'significant')<1)
errs=nnz(round(D6v./D10v(1:6),14,'significant')<1)

% hard to drop sig-figs to 8, but that is still high precision.
errs=nnz(round(abs(U3(:,1:3)./U6(:,1:3)),8,'significant')<1)
errs=nnz(round(abs(U3(:,1:3)./U10(:,1:3)),8,'significant')<1)
% had to drop one more for this comparison
errs=nnz(round(abs(U6(:,1:6)./U10(:,1:6)),7,'significant')<1)
%}
%whos('omni');
[U,D,~]=svds(omni,elb);
ase_Regional=U*sqrt(D);



if randomize_vertex_order
    % if we're randomizing order, fix ase_Regional data ordering to match input
    ase_Regional=reshape(ase_Regional,n_vertices,n_graphs,[]);
    ase_Regional(graph_order,:,:)=ase_Regional;
    ase_Regional=reshape(ase_Regional,n_vertices*n_graphs,[]);
end

%Sign is going to be bouncing around now but I cannot
%really do much about that without further investigation -> very little
%effect on the actual mds output so this is not a huge contributing factor
%to differences occuring in the space.
% ase_Regional=fliplr(abs(ase_Regional));
ase_Regional=fliplr(ase_Regional);  %% get in the order that python used in the original method.

tensor_ase=permute(reshape(ase_Regional,n_vertices,n_graphs,[]), [3,1,2]);

for roi=1:n_vertices/2
%     for n=1:n_graphs
%         tensor_ase_bilat(:,roi,n)=mean(tensor_ase(:,[roi roi+n_vertices/2],n),2);
%     end
    %It determines how different for each roi the specimen are (so we get
    %an estimate of contributions to ASE changes) -- BILATERALLY
    for n=1:n_graphs
        for m=1:n_graphs
            % This is semipar which is a frobien norm distance
            Dist_Regional_bilat(n,m,roi)=norm(tensor_ase(:,[roi roi+n_vertices/2],m)-tensor_ase(:,[roi roi+n_vertices/2],n),'fro');
        end
    end
    try
        [~,temp_eign_Full]=cmdscale(Dist_Regional_bilat(:,:,roi));
        [temp,temp_eign]=cmdscale(Dist_Regional_bilat(:,:,roi),2); %updated to remove the focusing on only the first! roi
        if size(temp,2)>1
            mds_Regional_bilat(:,:,roi) = temp;
            eigen_Regional_bilat(:,roi)= temp_eign./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
        else
            mds_Regional_bilat(:,:,roi) = [temp zeros(size(temp))];
            eigen_Regional_bilat(:,roi) =  [temp_eign 0]./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
        end
    catch
        mds_Regional_bilat(:,:,roi) = zeros(size(Dist_Regional_bilat,1),2);
        eigen_Regional_bilat(:,roi) =  [0 0];
    end
end

for roi=1:n_vertices
    %It determines how different for each roi the specimen are (so we get
    %an estimate of contributions to ASE changes) -- LEFT AND RIGHT
    %SEPARATE
    for n=1:n_graphs
        for m=1:n_graphs
            Dist_Regional(n,m,roi)=norm(tensor_ase(:,roi,m)-tensor_ase(:,roi,n),'fro'); %This is semipar!!!, frobian norm.
        end
    end
    try
        [~,temp_eign_Full]=cmdscale(Dist_Regional(:,:,roi));
        [temp,temp_eign]=cmdscale(Dist_Regional(:,:,roi),2); %updated to remove the focusing on only the first! roi
        if size(temp,2)>1
            mds_Regional(:,:,roi) = temp;
            eigen_Regional(:,roi)= temp_eign./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
            
        else
            mds_Regional(:,:,roi) = [temp zeros(size(temp))];
            eigen_Regional(:,roi) =  [temp_eign 0]./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
        end
    catch
        mds_Regional(:,:,roi) = zeros(size(Dist_Regional,1),2);
        eigen_Regional(:,roi) =  [0 0];
    end
end

%It determines how different each specimen is OVERALL (no concern about
%ROI just consider the on a whole difference)
for n=1:n_graphs
    for m=1:n_graphs
        Dist_Global(n,m)=norm(tensor_ase(:,:,m)-tensor_ase(:,:,n),'fro'); %This is semipar!!!, frobian norm. It matches what JHU Did
    end
end

%And get and embedding across all ROI
%So I'm re-embedding the resulting Distance map from the original ASE so
%that we get the coordinate space in non ROI corrdinates. that doesn't
%entirely make sense.... unless I think I care more about the distances
%being preserved in some way. but it really doesn't preserve the
%distances.... huh.... 

V=sort(eig(sqrt(Dist_Global*transpose(Dist_Global))),'descend');
elb=getElbows(V,3);

[U,D,~]=svds(Dist_Global,elb(2)); 
ase_Global=U*sqrt(D);
ase_Global=(fliplr(ase_Global));

%instead of doing weird double reembedding just find the average tensor ase
%response for each specimen across the ROI -- but this isn't really doing a
%dimension reduction.
%ase_Global=squeeze(mean(tensor_ase,2))';

% maybe another approach where we reduce the dimensionally along roi
% better?

%dim to reduce on needs to be between 1 and n_graphs
[~,eigen_Global_Full] = cmdscale(Dist_Global);
[mds_Global,eigen_Global] = cmdscale(Dist_Global,2);%Force 2D embedding This matches JHU

eigen_Global=eigen_Global./sum(eigen_Global_Full(eigen_Global_Full>0)); %Calcuates the percent of variablity explained by eigen values
end
