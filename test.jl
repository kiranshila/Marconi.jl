network

for index in CartesianIndices(network.s_params[:,:,1])
    print(network.s_params[index,:])
end

plot([1,2,3],[[1,4,9],[1,2,3],[4,5,6]])
prefix = Dict('Y'=> 1e24,'Z'=> 1e21,'E'=> 1e18,'P'=> 1e15,'T'=> 1e12,'G'=> 1e9,
              'M'=> 1e6,'k'=> 1e3,'h'=> 1e2,'d'=> 1e-1,'c'=> 1e-2,
              'm'=> 1e-3,'μ'=> 1e-6,'n'=> 1e-9,'p'=> 1e-12,'f'=> 1e-15,'a'=> 1e-18,
              'z'=> 1e-21,'y'=> 1e-24)
