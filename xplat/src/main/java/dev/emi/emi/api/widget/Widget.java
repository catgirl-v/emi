package dev.emi.emi.api.widget;

import java.util.List;

import dev.emi.emi.runtime.EmiDrawContext;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.Drawable;
import net.minecraft.client.gui.tooltip.TooltipComponent;

public abstract class Widget implements Drawable {

	public abstract Bounds getBounds();
	
	@Override
	public void render(DrawContext raw, int mouseX, int mouseY, float delta) {
		render(EmiDrawContext.wrap(raw), mouseX, mouseY, delta);
	}

	public abstract void render(EmiDrawContext context, int mouseX, int mouseY, float delta);

	public List<TooltipComponent> getTooltip(int mouseX, int mouseY) {
		return List.of();
	}
	
	public boolean mouseClicked(int mouseX, int mouseY, int button) {
		return false;
	}

	public boolean keyPressed(int keyCode, int scanCode, int modifiers) {
		return false;
	}
}
