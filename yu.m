%最新版改进Salam网络拓扑随机生成算法通用MATLAB源码
%{
SalamNet_NetCreate(1000,25,100000000,200000000000,1,[2,5],[30,1000],[2,4],1e-4*[5,20],1e-4*[3,8],1e-4*[0,500])
本程序为最新版源码，源码无删减，能绘出漂亮的网络拓扑图片，算法改进说明如下：
1.使用K均值聚类控制节点分布的疏密，使得产生的网络拓扑连通性和均匀性更好
2.产生的网络拓扑数据丰富，包括：链路的费用、时延、带宽，节点的费用、时延、时延抖动、丢包率
3.链路时延等于节点距离除以三分之二光速，更加符合实际情况
%}

function [Sxy,AM,EdgeCost,EdgeDelay,EdgeBandWide,VertexCost,VertexDelay,VertexDelayJitter,VertexPacketLoss]=SalamNet_NetCreate(BorderLength,NodeAmount, ...,
    Alpha,Beta,PlotIf,EdgeCostDUB,EdgeBandWideDUB,VertexCostDUB,VertexDelayDUB,VertexDelayJitterDUB,VertexPacketLossDUB)
%%改进的 Salama网络拓扑随机生成算法
%%算法说明 
%? 1.使用K均值聚类控制节点分布的疏密，使得产生的网络拓扑连通性和均匀性更好
%? 2.产生的网络拓扑数据丰富，包括：链路的费用、时延、带宽，节点的费用、时延、时延抖动、丢包率
%? 3.链路时延等于节点距离除以三分之二光速，更加符合实际情况
%% 输入参数列表
%BorderLenght————正方形区域的边长，单位：km
%NodeAmount————网络节点的个数
%Alpha————网络特征参数，Alpha越大，短边相对长边的比例越大
%Beta————网络特征参数，Beta越大，边的密度越大
%PlotIf————是否画网络拓扑图，如果为1，则画图，否则不画图
%EdgeCostDUB————链路费用的控制参数，1*2，存储链路费用的下界和上界
%EdgeBandWideDUB————链路带宽的控制参数，1*2，存储下界和上界
%VertexCostDUB————节点费用的控制参数，1*2,存储节点费用的下界和上界
%VertexDelayDUB————节点时延的控制参数，1*2，节储节点时延的下界和上界
%VertexDelayJitterDUB————节点时延抖动的控制参数，1*2，存储节点时延抖动的下界和上界
%VertexPacketLossDUB————节点丢包率的控制参数，1*2,存储节点丢包率的下界
%%输出参数
%Sxy————3*N的矩阵，各列分别用于存储节点的序号，横坐标，纵坐标的矩阵
%AM————0 1存储矩阵，AM(i,j)=1表示存在由i到j的有向边，N*N
%EdgeCost————链路费用矩阵，N*N
%EdgeDelay————链路时延矩阵，N*N
%EdgeBandWide————链路带宽矩阵，N*N
%VertexCost————节点费用向量,1*N
%VertexDelay————节点时延向量，1*N
%VertexDelayJitter————节点时延抖动向量,1*N
%VertexPacketLoss————节点丢包率向量,1*N
%%推荐的输入参数设置 
BorderLength=1000;NodeAmount=25;Alpha=100000000;Beta=200000000000;
PlotIf=1;EdgeCostDUB=[2,5];EdgeBandWideDUB=[30,1000];VertexCostDUB=[2,4];
VertexDelayDUB=1e-4*[5,20];VertexDelayJitterDUB=1e-4*[3,8];
VertexPacketLossDUB=1e-4*[0,500]
%%
%参数初始化
NN = 10*NodeAmount;
SSxy = zeros(NN,2);
%在正方形区域内随机均匀选取NN个节点
for i = 1:NN
    SSxy(i,1) = BorderLength*rand;
    SSxy(i,2) = BorderLength*rand;
 %   plot( SSxy(i,1),SSxy(i,2));
end

[IDX,C] = kmeans(SSxy,NodeAmount);
Sxy = [[1:NodeAmount]',C]';
%按横坐标由小到大的顺序重新为每一个节点编号
temp = Sxy;
Sxy2 = Sxy(2,:);
Sxy2_sort = sort(Sxy2);
for i = 1:NodeAmount
    pos = find(Sxy2==Sxy2_sort(i));
    if length(pos)>1
        error('仿真故障，请重试！');
    end
    temp(1,i) = i;
    temp(2,i) = Sxy(2,pos);
    temp(3,i) = Sxy(3,pos);
end
Sxy = temp;
%输出参数初始化
AM = zeros(NodeAmount,NodeAmount);
EdgeCost = zeros(NodeAmount,NodeAmount);
EdgeDelay = zeros(NodeAmount,NodeAmount);
EdgeBandWide = zeros(NodeAmount,NodeAmount);
VertexCost  = zeros(1,NodeAmount);
VertexDelay = zeros(1,NodeAmount);
VertexDelayJitter = zeros(1,NodeAmount);
VertexPacketLoss  = zeros(1,NodeAmount);
for i = 1:(NodeAmount-1)
    for j = (i+1):NodeAmount
        Distance =( (Sxy(2,i)-Sxy(2,j))^2+(Sxy(3,i)-Sxy(3,j))^2)^0.5;
        P = Beta*exp(-Distance^5/(Alpha*BorderLength));
        if P>rand
            AM(i,j) = 1;
            AM(j,i) = 1;
            EdgeDelay(i,j) = 0.5*Distance/100000;
            EdgeDelay(j,i) = EdgeDelay(i,j);
            EdgeCost(i,j) = EdgeCostDUB(1)+(EdgeCostDUB(2)-EdgeCostDUB(1))*rand;
            EdgeCost(j,i)=EdgeCost(i,j);
            EdgeBandWide(i,j) = EdgeBandWideDUB(1)+(EdgeBandWideDUB(2)-EdgeBandWideDUB(1))*rand;
            EdgeBandWide(j,i)=EdgeBandWide(i,j);
        else
            EdgeDelay(i,j) = inf;
            EdgeDelay(j,i) = inf;
            EdgeCost(i,j) = inf;
            EdgeCost(j,i) = inf;
            EdgeBandWide(i,j) = inf;
            EdgeBandWide(j,i) = inf;
        end
    end
end
for i = 1:NodeAmount
    VertexCost(i) = VertexCostDUB(1)+(VertexCostDUB(2)-VertexCostDUB(1))*rand;
    VertexDelay(i) = VertexDelayDUB(1)+(VertexDelayDUB(2)-VertexDelayDUB(1))*rand;
    VertexDelayJitter(i) = VertexDelayJitterDUB(1)+(VertexDelayJitterDUB(2)-VertexDelayJitterDUB(1))*rand;
    VertexPacketLoss(i) = VertexPacketLossDUB(1)+(VertexPacketLossDUB(2)-VertexPacketLossDUB(1))*rand;
end
Net_plot(BorderLength,NodeAmount,Sxy,EdgeCost,PlotIf);
end

%用于绘制网络拓扑的函数
function Net_plot(BorderLength,NodeAmount,Sxy,EdgeCost,PlotIf)
%画节点
if PlotIf == 1
    plot(Sxy(2,:),Sxy(3,:),'ko','MarkerEdgeColor','b','MarkerFaceColor','g','MarkerSize',5);
    %设置图形显示范围
    xlim([0,BorderLength]);
    ylim([0,BorderLength]);
    hold on;
    %节点标序号
    for i = 1:NodeAmount
        Str = int2str(i);
        text(Sxy(2,i)+BorderLength/100,Sxy(3,i)+BorderLength/100,Str,'FontName','Times New Roman','FontSize',12);
        hold on;
    end
end
%画边
if PlotIf == 1
    for i = 1:(NodeAmount-1)
        for j = (i+1):NodeAmount
            if isinf(EdgeCost(i,j)) == 0
                plot([Sxy(2,i),Sxy(2,j)],[Sxy(3,i),Sxy(3,j)]);
                hold on;
            end
        end
    end
end
if PlotIf == 1
    xlabel('x (km)','FontName','Times New Roman','FontSize',12);
    ylabel('y (km)','FontName','Times New Roman','FontSize',12);
end
end
