
cd('J:\Exp1\Plots_Paper1\Publication'); %% define your own path

function make_all_figs()
root = project_root();

data = readtable(fullfile(root, 'Exp1_30_dataset.csv'));
data = convert_cells_to_categorical(data);
stats = compute_stats(data);

plot_rt(stats, root);
plot_accuracy(stats, root);
plot_IES(root);
plot_tf_diff(root);
plot_corr_chew_theta(root);
plot_pli(root);
plot_erp(root);
plot_supplemental_1A(root);
plot_supplemental_1B(root);
plot_supplemental_1C(root);
plot_supplemental_2A(root);
plot_supplemental_2B(root);

end

make_all_figs();


function root = project_root()
thisfile = mfilename('fullpath');
root = fileparts(thisfile);
end

function data = convert_cells_to_categorical(data)
for i = 1:width(data)
    col = data{:, i};
    if iscell(col) && all(cellfun(@ischar, col))
        data.(data.Properties.VariableNames{i}) = categorical(col);
    end
end
end

function stats = compute_stats(data)
sem = @(x) std(x,'omitnan')/sqrt(sum(~isnan(x)));
cond_tbrt = data.target==categorical("Target") & data.rand_view==1;
p1 = prctile(data.k_tbrt(cond_tbrt),1);
p99 = prctile(data.k_tbrt(cond_tbrt),99);
cond_prtb = cond_tbrt & data.k_tbrt>p1 & data.k_tbrt<p99;

conds = {'Planochew','Placebo','Non-Chewing';
    'Plachew','Placebo','Chewing';
    'Anenochew','Anesthesia','Non-Chewing';
    'Anechew','Anesthesia','Chewing'};
n=nan(4,1); acc=nan(4,1); sem_acc=nan(4,1);
m_tbrt=zeros(4,1); s_tbrt=zeros(4,1);
colors = [0.2 0.6 0.8;0.8 0.4 0.6;0.2 0.6 0.8;0.8 0.4 0.6];

for i=1:4
    ane=conds{i,2}; chew=conds{i,3};
    filt_full = cond_tbrt & data.ane == categorical(string(ane)) & data.chew == categorical(string(chew));
    filt_trim = cond_prtb & data.ane == categorical(string(ane)) & data.chew == categorical(string(chew));
    n(i)=sum(filt_full);
    acc(i)=sum(filt_full & ~isnan(data.k_tbrt))/n(i);
    sem_acc(i)=sqrt(acc(i)*(1-acc(i))/n(i));
    m_tbrt(i)=mean(data.k_tbrt(filt_trim),'omitnan')*1000;
    s_tbrt(i)=sem(data.k_tbrt(filt_trim))*1000;
end

lm = fitlm(data(cond_tbrt,:), 'k_tbrt_m ~ ane*chew');
rm = fitrm(data(cond_tbrt,:), 'k_tbrt_m ~ chew*ane');
ptab = multcompare(rm,'chew','By','ane').pValue;
p_rt_pla = ptab(3,1); p_rt_ane = ptab(1,1);

subjects = unique(data.participant);
T = table('Size',[0 4],'VariableTypes',{'double','string','string','double'}, ...
    'VariableNames',{'participant','ane','chew','accuracy'});
idx=1;
for s=1:length(subjects)
    sid=subjects(s);
    for i=1:4
        ane=conds{i,2}; chew=conds{i,3};
        mask = data.participant==sid & cond_tbrt & ...
            data.ane == categorical(string(ane)) & ...
            data.chew == categorical(string(chew));
        tot=sum(mask); corr=sum(mask & ~isnan(data.k_tbrt));
        T(idx,:)={sid,ane,chew,corr/tot}; idx=idx+1;
    end
end
T.ane=categorical(T.ane); T.chew=categorical(T.chew);
T.participant=categorical(T.participant);
T.group=categorical(strcat(string(T.ane),'_',string(T.chew)));
lme = fitlme(T,'accuracy ~ ane*chew + (1|participant)');
lme_post = fitlme(T,'accuracy ~ group + (1|participant)');
cn = lme_post.CoefficientNames;
C = zeros(2,length(cn));
C(1,strcmp(cn,'group_Anesthesia_Non-Chewing'))=1;
C(1,strcmp(cn,'group_Anesthesia_Chewing'))=-1;
C(2,strcmp(cn,'group_Placebo_Non-Chewing'))=1;
C(2,1)=-1;
p_acc = nan(2,1);
for i=1:2
    p_acc(i)=coefTest(lme_post,C(i,:));
end
stats = struct('m_tbrt',m_tbrt,'s_tbrt',s_tbrt,'acc',acc,'sem_acc',sem_acc, ...
    'p_values',struct('rt_pla',p_rt_pla,'rt_ane',p_rt_ane,'acc_pla',p_acc(2),'acc_ane',p_acc(1)),...
    'colors',colors,'rt_limits',[550 620],'acc_limits',[50 80],'lm',lm,'lme',lme);
end

%% — Plot Functions —

function plot_rt(stats,root)
fig=figure('Position',[100 100 400 600]); hold on;
b=bar(stats.m_tbrt,'FaceColor','flat');
for k=1:4, b.CData(k,:)=stats.colors(k,:); end
errorbar(b.XData,stats.m_tbrt,stats.s_tbrt,'k','LineStyle','none','LineWidth',1.5);
ylim(stats.rt_limits); xticks(1:4); xticklabels({'No‑Chew','Chew','No‑Chew','Chew'});
text(1.5,min(ylim)-10,'Placebo','HorizontalAlignment','center','FontWeight','bold');
text(3.5,min(ylim)-10,'Anesthesia','HorizontalAlignment','center','FontWeight','bold');
annotate_significance(stats.p_values.rt_pla,stats.p_values.rt_ane,stats.m_tbrt,stats.s_tbrt);
ylabel('Mean RT (ms)'); box on; hold off;
savefig_or_print(fig,root,'1a_RT');
end

function plot_accuracy(stats,root)
fig=figure('Position',[100 100 400 600]); hold on;
m = stats.acc*100; s = stats.sem_acc*100;
b = bar(m,'FaceColor','flat');
for k=1:4, b.CData(k,:)=stats.colors(k,:); end
errorbar(b.XData,m,s,'k','LineStyle','none','LineWidth',1.5);
ylim(stats.acc_limits); xticks(1:4); xticklabels({'No‑Chew','Chew','No‑Chew','Chew'});
text(1.5,min(ylim)-2,'Placebo','HorizontalAlignment','center','FontWeight','bold');
text(3.5,min(ylim)-2,'Anesthesia','HorizontalAlignment','center','FontWeight','bold');
annotate_significance(stats.p_values.acc_pla,stats.p_values.acc_ane,m,s);
ylabel('Accuracy Rate (%)'); box on; hold off;
savefig_or_print(fig,root,'1b_ACC');
end

function plot_IES(root)
load(fullfile(root,'f1a.mat'),'ies_plot');
fig=figure; bar(1,ies_plot.mean_IES_per,'FaceColor',[0.8 0.4 0.2]);
hold on; errorbar(1,ies_plot.mean_IES_per,ies_plot.ci_IES_per/2,'k','LineWidth',1,'CapSize',10);
xlim([0.5 1.5]); ylabel('IES reduction (%)');
y_min=ies_plot.mean_IES_per - ies_plot.ci_IES_per -3;
line([0.85 1.15],[y_min y_min],'Color','k','LineWidth',1.5);
text(1,y_min+1,ies_plot.p_plot,'HorizontalAlignment','center','FontSize',14,'FontWeight','bold');
box on; hold off;
savefig_or_print(fig,root,'1c_IES');
end

function plot_tf_diff(root)
load(fullfile(root,'f1b_tfdiff.mat'),'data','condicion');
fig=figure; bar(mean(data)); hold on;
errorbar(1:2,mean(data),std(data)/sqrt(size(data,1)),'k','LineStyle','none','LineWidth',1.5);
xticks(1:2); xticklabels(condicion); ylabel('Power (dB)');
[hn1,pnor1]=adtest(data(:,1)); [hn2,pnor2]=adtest(data(:,2));
if ~hn1 && ~hn2
    [~,p1]=ttest(data(:,1),data(:,2),'Tail','left');
else
    p1 = ranksum(data(:,1),data(:,2),'tail','left');
end
if p1<0.05
    sym=significance_symbol(p1);
    y_sig=max(mean(data)+std(data)/sqrt(size(data,1))) + .1;
    line([1 2],[y_sig y_sig],'Color','k','LineWidth',1.5);
    text(1.5,y_sig+.02,sym,'FontSize',18,'FontWeight','bold','HorizontalAlignment','center');
end
ylim([min(mean(data)-std(data)/sqrt(size(data,1))) max(mean(data)+std(data)/sqrt(size(data,1)))+0.2]);
box on; hold off;
savefig_or_print(fig,root,'1d_TFdiff');
end

function plot_corr_chew_theta(root)
load(fullfile(root,'data_chew.mat'),'data_chew');
load(fullfile(root,'fic_tf.mat'),'data_tf');
x=data_chew.Global_Frequency; y=data_tf.Freq_C2;
valid = ~isnan(x)&~isnan(y); x=x(valid); y=y(valid);
[rho,pval]=corr(x,y,'Type','Spearman','Tail','right');
fig=figure; scatter(x,y,50,[0.8 0.4 0.6],'filled'); hold on;
coef=polyfit(x,y,1); xx=linspace(min(x),max(x),100); yy=polyval(coef,xx);
plot(xx,yy,'r-','LineWidth',2);
text(min(x)+0.03*range(x),max(y)+0.07*range(y),sprintf("ρ = %.2f\np = %.3f",rho,pval), ...
    'FontSize',12,'FontWeight','bold');
xlabel('Chew Frequency (Hz)'); ylabel('θ Frequency (Hz)'); box on; hold off;
savefig_or_print(fig,root,'1e_CORR');
end


function plot_pli(root)
load(fullfile(root,'f1d_pli.mat'),'pli_fig');
chanlocs=pli_fig.chanlocs; pli_diff=pli_fig.pli_diff;
dico_no=pli_fig.dico_unique_no_chew; dico_chew=pli_fig.dico_unique_chew;
fig=figure('Position',[100 100 1000 400]);
ax1=subplot(2,5,[1,7]);
topoplot(pli_diff,chanlocs,'maplimits',[-max(abs(pli_diff)) max(abs(pli_diff))],'numcontour',0,'colormap','jet');
hold on; [~,grid,~,xi,yi]=topoplot(pli_diff,chanlocs,'noplot','on','gridscale',100,'style','map');
contour(xi,yi,grid,[0.075 0.075],'LineColor','w','LineWidth',1.5); hold off;
colorbar('Location','southoutside');
ax2=subplot(2,5,[3,9]); imagesc(zeros(size(dico_no))); colormap(ax2,[1 1 1]);
hold on; [xn,yn]=find(dico_no); scatter(yn,xn,30,'s','filled','MarkerFaceColor',[0 0 1]);
[xc,yc]=find(dico_chew); scatter(yc,xc,30,'s','filled','MarkerFaceColor',[1 0 0]); hold off;
axis square; xticks(10:10:60); yticks(10:10:60);
xlabel('Channels'); ylabel('Channels'); legend('Location','southoutside','Orientation','horizontal');
ax3=subplot(2,5,[5,10]); axis off;
for idx=1:numel(chanlocs)
    text(mod(idx-1,2)/2+0.01,1-floor((idx-1)/2)/ceil(numel(chanlocs)/2)+1/(2*ceil(numel(chanlocs)/2)), ...
        sprintf('%02d‑%s',idx,chanlocs(idx).labels),'Units','normalized','FontSize',8,'HorizontalAlignment','left');
end
box on;
savefig_or_print(fig,root,'1f_PLI');
end

function plot_erp(root)
load(fullfile(root,'f1e_erp.mat'),'ERP_data');
fig=figure('Position',[100 100 600 600]); hold on;
colors={[0.2 0.6 0.8],[0.8 0.4 0.6]};
for i=1:numel(ERP_data.mean_erp)
    plot(ERP_data.times,squeeze(ERP_data.mean_erp{i}),'LineWidth',2.2,'Color',colors{i});
end
yl=[-3 3];
line([ERP_data.time_window(1),ERP_data.time_window(2)],[yl(2)-0.5 yl(2)-0.5],'Color','k','LineWidth',2);
if ERP_data.p_value<0.001, st='***'; elseif ERP_data.p_value<0.01, st='**'; elseif ERP_data.p_value<0.05, st='*'; else st='n.s.'; end
text(mean(ERP_data.time_window),yl(2)-0.4,st,'FontSize',14,'FontWeight','bold','HorizontalAlignment','center');
xline(0,'--k'); yline(0,'--k'); xlabel('Time (ms)'); ylabel('Amplitude (μV)');
xlim([-200 700]); ylim(yl); legend({'No chew','Chew'},'Location','northeast'); box on; hold off;
savefig_or_print(fig,root,'1g_ERP');
end

function plot_supplemental_1A(root)
    load(fullfile(root,'s1a.mat'),'accuracy');
    semf = @(x) std(x,'omitnan')/sqrt(sum(~isnan(x)));
    labels = {'Placebo_Non_Chewing','Placebo_Chewing','Anesthesia_Non_Chewing','Anesthesia_Chewing'};
    bar_acc = nan(4,1); bar_sacc = nan(4,1);
    for i=1:4
        acc = accuracy.(labels{i}).accuracy;
        bar_acc(i) = mean(acc,'omitnan');
        bar_sacc(i) = semf(acc);
    end
    colors = [0.2 0.6 0.8; 0.8 0.4 0.6; 0.2 0.6 0.8; 0.8 0.4 0.6];
    limites = [80 95];
    p = [0.018, 0.0001];
    fig = figure('Color','w','Position',[100 100 400 600]); hold on;
    b = bar(bar_acc,'FaceColor','flat','BarWidth',0.7);
    b.CData = colors;
    errorbar(b.XData,bar_acc,bar_sacc,'k','LineStyle','none','LineWidth',1.5,'CapSize',5);
    ylim(limites); xticks(1:4); xticklabels({'No‑Chew','Chew','No‑Chew','Chew'});
    text(1.5,limites(1)-1,'Placebo','HorizontalAlignment','center','FontWeight','bold');
    text(3.5,limites(1)-1,'Anesthesia','HorizontalAlignment','center','FontWeight','bold');
    yl = limites(2);
    for idx = 1:2
        x = [2*idx-1,2*idx];
        sym = significance_symbol(p(idx));
        plot(x,[yl-1 yl-1],'k-','LineWidth',1.5);
        text(mean(x),yl-0.9,sym,'HorizontalAlignment','center','FontWeight','bold');
    end
    ylabel('Accuracy Rate (%)');
    title({'Accuracy rate','Visual Oddball'},'FontSize',16,'FontWeight','bold');
    box on; hold off;
    savefig_or_print(fig,root,'supp1a_ACC');
end

function plot_supplemental_1B(root)
    load(fullfile(root,'s1b.mat'),'bar_means','bar_sems','p_vort_pla','p_vort_ane');
    colors = [0.2 0.6 0.8;0.8 0.4 0.6;0.2 0.6 0.8;0.8 0.4 0.6];
    limites = [460 475];
    fig = figure('Color','w','Position',[100 100 400 600]); hold on;
    b = bar(bar_means,'FaceColor','flat','BarWidth',0.7);
    b.CData = colors;
    errorbar(b.XData,bar_means,bar_sems,'k','LineStyle','none','LineWidth',1.5,'CapSize',5);
    ylim(limites); xticks(1:4); xticklabels({'No‑Chew','Chew','No‑Chew','Chew'});
    text(1.5,limites(1)-1,'Placebo','HorizontalAlignment','center','FontWeight','bold');
    text(3.5,limites(1)-1,'Anesthesia','HorizontalAlignment','center','FontWeight','bold');
    for idx=1:2
        p = (idx==1)*p_vort_pla + (idx==2)*p_vort_ane;
        sym = significance_symbol(p);
        x = [2*idx-1,2*idx];
        plot(x,[limites(2)-2 limites(2)-2],'k-','LineWidth',1.5);
        text(mean(x),limites(2)-1,sym,'HorizontalAlignment','center','FontWeight','bold');
    end
    ylabel('Reaction Time (ms)');
    title({'Reaction time','Visual Oddball'},'FontSize',16,'FontWeight','bold');
    box on; hold off;
    savefig_or_print(fig,root,'supp1b_RT');
end

function plot_supplemental_1C(root)
    load(fullfile(root,'s1c.mat'),'mean_IES_per','ci_IES_per','p_plot');
    fig = figure('Color','w','Position',[100 100 400 600]); hold on;
    bar(1,mean_IES_per,'FaceColor',[0.4 0.8 0.6],'EdgeColor','k','BarWidth',0.4);
    errorbar(1,mean_IES_per,ci_IES_per/2,'k','LineWidth',1,'CapSize',10);
    xlim([0.5 1.5]);
    ylim([min(mean_IES_per-ci_IES_per)-4,0]);
    ylabel('IES reduction (%)');
    title('Percentage Difference in IES','FontSize',14,'FontWeight','bold');
    y_min = mean_IES_per - ci_IES_per - 3;
    line([0.85 1.15],[y_min y_min],'Color','k','LineWidth',1.5);
    text(1,y_min+1,p_plot,'HorizontalAlignment','center','FontSize',14,'FontWeight','bold');
    box on; hold off;
    savefig_or_print(fig,root,'supp1c_IES');
end

function plot_supplemental_2A(root)
    load(fullfile(root,'s2a.mat'),'plot_data');
    tf = plot_data.tf; chanlocs = plot_data.chanlocs;
    times = plot_data.times; frex = plot_data.frex; labels = plot_data.labels;
    electrodes = plot_data.electrodes; lim = [-2 2]; tf_plot = plot_data.tf_plot;
    condicion = plot_data.condicion; nSubs = size(tf,5);
    time = [350 550]; freq = [4 7];
    timeidx = dsearchn(times',time'); freqidx = dsearchn(frex',freq');
    for i=1:2
        fig = figure('Color','w','Position',[100 100 400 400]);
        contourf(times,frex,squeeze(mean(tf(i,:,:,:,:),[2 5])),60,'linecolor','none');
        colormap(jet); set(gca,'clim',lim); xlim(tf_plot); ylim([1 20]); axis square;
        xlabel('Time (ms)'); ylabel('Frequency (Hz)');
        rectangle('Position',[time(1) freq(1) diff(time) diff(freq)],'LineWidth',2);
        colorbar;
        title(condicion{i},'FontWeight','bold');
        savefig_or_print(fig,root,['supp2a_TF_' lower(condicion{i})]);
    end
    fig = figure('Color','w','Position',[100 100 400 400]);
    grandAve = squeeze(mean(tf(:,:,:,:,:),[1 2 5]));
    contourf(times,frex,grandAve,60,'linecolor','none');
    colormap(jet); set(gca,'clim',lim); xlim(tf_plot); ylim([1 20]); axis square;
    xlabel('Time (ms)'); ylabel('Frequency (Hz)'); title('Grand average');
    rectangle('Position',[time(1) freq(1) diff(time) diff(freq)],'LineWidth',2);
    colorbar; savefig_or_print(fig,root,'supp2a_TF_GAv');

    topo_labels = labels;
    for j=1:2
        fig = figure('Color','w','Position',[100 100 400 400]);
        topo_data = squeeze(mean(tf(j,:,freqidx(1):freqidx(2),timeidx(1):timeidx(2),:),[3 4 5]));
        topoplot(topo_data,chanlocs);
        set(gca,'CLim',lim); colorbar; title(condicion{j},'FontWeight','bold');
        savefig_or_print(fig,root,['supp2a_Topo_' lower(condicion{j})]);
    end
    fig = figure('Color','w','Position',[100 100 400 300]);
    data = nan(nSubs,2);
    data(:,1) = squeeze(mean(tf(1,electrodes,freqidx(1):freqidx(2),timeidx(1):timeidx(2),:),[2 3 4]));
    data(:,2) = squeeze(mean(tf(2,electrodes,freqidx(1):freqidx(2),timeidx(1):timeidx(2),:),[2 3 4]));
    [~,p1] = ttest(data(:,1),data(:,2),'Tail','left');
    barh(1,mean(data(:,1)),'FaceColor',[0.4940 0.1840 0.5560]); hold on;
    barh(2,mean(data(:,2)),'FaceColor',[0 0.4470 0.7410]); set(gca,'YTick',1:2,'YTickLabel',strrep(topo_labels,'_','\_'));
    errorbar(mean(data),1:2,zeros(size(data)),std(data)/sqrt(nSubs),'.','horizontal');
    xlabel('Power (dB)'); text(mean(data(:,1)),0.4,['p = ' num2str(round(p1,3))],'FontSize',10,'FontWeight','bold');
    title('ROI Power Comparison','FontWeight','bold');
    savefig_or_print(fig,root,'supp2a_Bar_Power');
end

function plot_supplemental_2B(root)
    load(fullfile(root,'s2b.mat'),'EEG_demo','avg_pli_all','pli_dico');
    chanlocs = EEG_demo.chanlocs;
    pli_diff = avg_pli_all{2} - avg_pli_all{1};
    dico_no = squeeze(pli_dico(1,:,:)&~pli_dico(2,:,:));
    dico_chew = squeeze(pli_dico(2,:,:)&~pli_dico(1,:,:));
    fig = figure('Color','w','Position',[100 100 1000 400]);
    ax1 = subplot(2,5,[1,7]);
    topoplot(pli_diff,chanlocs,'maplimits',[-max(abs(pli_diff)) max(abs(pli_diff))],'numcontour',0,'colormap','jet');
    hold on; [~,grid,~,xi,yi]=topoplot(pli_diff,chanlocs,'noplot','on','gridscale',100,'style','map');
    contour(xi,yi,grid,[0.075 0.075],'LineColor','w','LineWidth',1.5); hold off;
    colorbar('Location','southoutside');
    ax2 = subplot(2,5,[3,9]);
    imagesc(zeros(size(dico_no))); colormap(ax2,[1 1 1]); hold on;
    [xn,yn]=find(dico_no); scatter(yn,xn,20,'s','filled','MarkerFaceColor',[0 0 1]);
    [xc,yc]=find(dico_chew); scatter(yc,xc,20,'s','filled','MarkerFaceColor',[1 0 0]); hold off;
    axis square; xticks(10:10:60); yticks(10:10:60); xlabel('Channels'); ylabel('Channels');
    legend('Location','southoutside','Orientation','horizontal');
    ax3 = subplot(2,5,[5,10]); axis off;
    for idx=1:numel(chanlocs)
        row=floor((idx-1)/2); col=mod(idx-1,2);
        x=col/2+0.01; y=1-(row+1)/ceil(numel(chanlocs)/2)+1/(2*ceil(numel(chanlocs)/2));
        text(x,y,sprintf('%02d‑%s',idx,chanlocs(idx).labels),'Units','normalized','FontSize',8,'HorizontalAlignment','left');
    end
    box on;
    savefig_or_print(fig,root,'supp2b_PLI');
end

%% — Utilidades comunes —

function annotate_significance(ppla,pane,means,sems)
for idx=1:2
    p = (idx==1)*ppla + (idx==2)*pane;
    sym = significance_symbol(p);
    y = max(means([(idx*2-1) idx*2]) + sems([(idx*2-1) idx*2])) + diff(ylim)*0.05;
    x = mean([idx*2-1 idx*2]);
    plot([idx*2-1 idx*2],[y y],'k-','LineWidth',1.5);
    text(x,y+diff(ylim)*0.02,sym,'HorizontalAlignment','center','FontWeight','bold');
end
end

function sym = significance_symbol(p)
if p<1e-4, sym='****'; elseif p<1e-3, sym='***';
elseif p<=0.05, sym='*'; else sym='n.s.'; end
end

function savefig_or_print(fig,root,name)
saveas(fig, fullfile(root, [name '.png']));
print(fig, fullfile(root, name), '-dpng', '-r300');
end

