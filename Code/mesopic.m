function [Lphoto, Lscoto, Lmeso, m] = mesopic(spd, CIETable)
interp_arg = 'linear';
Lphoto = [];
Lscoto = [];
Lmeso = [];
m = [];
if (length (spd) > 2)
    inds = spd(:, 1) >= 360 & spd(:, 1) <= 830;
    spd = spd(inds, :);

    spswl = spd(:, 1);
  
    wavl1nmp = CIETable.Photopic.wl;
    ybar1nmp = CIETable.Photopic.Y;
    ybarp = interp1 (wavl1nmp, ybar1nmp, spswl, interp_arg, 0);

    wavl1nms = CIETable.Scotopic.wl;
    ybar1nms = CIETable.Scotopic.Vp;
    ybars = interp1 (wavl1nms, ybar1nms, spswl, interp_arg, 0);

    ns = size(spd, 2)-1;
    C = 683 / 1700; %# photopic / scotopic gains
    a = 1 - log10(5)/3;
    b = 1.0/3;
    Fm = @(m, Lp, Ls) ((m*Lp+(1-m)*Ls*C)/(m-(1-m)*C) - 10^((m-a)/b));
    dFm = @(m, Lp, Ls) ((Lp*C*(1-Ls/Lp)/((m+(1-m)*C)^2)) - 10^((m-a)/b)*log(10)/b);

    s = size(ns:-1:1,2);
    m = zeros(1,s);
    Lphoto = m;
    Lscoto = m;
    Lmeso = m;
    for indj = (ns:-1:1)
        wspdsrc = spd(:, 1+indj);
        Lphoto(1, indj) = 683 * trapz(spswl, wspdsrc.*ybarp);
        Lscoto(1, indj) = 1700 * trapz(spswl, wspdsrc.*ybars);

        if (Lscoto(1, indj) <= 5e-3)
            m(1, indj) = 0;
            Lmeso(1, indj) = Lscoto(1, indj);
        elseif (Lphoto(1, indj) >= 5)
            m(1, indj) = 1;
            Lmeso(1, indj) = Lphoto(1, indj);
        else
            m0 = .5; ak = 0; bk = 1;
            F0 = Fm(m0, Lphoto(1, indj), Lscoto(1, indj));
            niter = 0;
            tt = zeros(2, 0, "double");
            while ((abs(F0) > 1e-5 * 10^((m0-a)/b)) && (niter < 101))
                dF0 = dFm(m0, Lphoto(1, indj), Lscoto(1, indj));
                if (F0 > 0)
                    ak = m0;
                else
                    bk = m0;
                end
                mn = m0 - F0 / dF0;
                if (mn < ak) || (mn > bk)
                    mn = .5*(ak + bk); %# switch to bisection
                end
                m0 = mn;
                F0 =  Fm(m0, Lphoto(1, indj), Lscoto(1, indj));
                tt = [tt [m0; F0]];
                niter = niter + 1;
            end
            m(1, indj) = m0;
            Lmeso(1, indj) = (m0 * Lphoto(1, indj) + (1-m0) * Lscoto(1, indj)*C) / (m0 + (1-m0) * C);
        end
    end
end
